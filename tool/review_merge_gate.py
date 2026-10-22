"""Runs the automated merge gate of a reviewed pull request.

The OpenCode review workflow grades a pull request `A`, `B`, `C` or `D`.
Only grade `A` is merge-ready: the gate then labels the pull request
`automerge`, approves it and merges it. Every other grade (`B`, `C`, `D`)
and a missing grade leave the pull request open and drop a possibly stale
`automerge` label, so the label-driven auto-merge workflow cannot pick the
pull request up either.

The decision lives in this script (and not in the workflow YAML) so that it
can be unit tested:

  python3 -m unittest tool.test_review_merge_gate -v

The gate never invents a grade: the grade is parsed from the model's own
final message by `tool/parse_review_grade.py` and handed over as-is. Only
the exact grade `A` merges - everything else holds the pull request, so the
gate fails closed.

The grade is bound to the commit that was actually reviewed
(`--reviewed-sha`): when the head commit of the pull request moved while
the review ran, the grade belongs to a commit that is no longer the head,
so it is not recorded and nothing is merged.

The verdict is also recorded as a commit status on the head commit of the
pull request (`opencode-review-grade`). The auto-merge workflow re-checks
that status before it merges anything, so a pull request that received new
commits after an `A` grade is never merged on the strength of that old
grade, and a pull request whose review never finished is never merged
either.

Usage:
  # Before the review runs: fail closed (drop a stale label, mark the head
  # commit as "review pending").
  python3 tool/review_merge_gate.py prepare --pr 57

  # After the review: record the grade and apply the gate. The reviewed
  # commit is the head commit of the pull request when the diff was built.
  python3 tool/review_merge_gate.py gate --pr 57 --grade A --reviewed-sha 1dcfe7a

  # Before the auto-merge workflow merges: drop the label from every open
  # pull request that is not merge-ready.
  python3 tool/review_merge_gate.py enforce

Exit codes:
  0  the gate ran (a failing GitHub call is reported as a warning)
  1  the gate could not be applied (e.g. the reviewed commit is no longer
     the head commit, or a stale label could not be dropped, so nothing
     was merged)
  2  the command line was invalid
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
from dataclasses import dataclass
from typing import Callable, Sequence

AUTOMERGE_LABEL = "automerge"
LABEL_DESCRIPTION = "Merge-ready per automated review; eligible for automerge."
LABEL_COLOR = "0E8A16"
MERGE_GRADE = "A"
GRADES = ("A", "B", "C", "D")
REVIEW_STATUS_CONTEXT = "opencode-review-grade"
PENDING_DESCRIPTION = "GRADE=pending review in progress"
GRADE_STATUS_PATTERN = re.compile(r"^GRADE=(A|B|C|D|none|pending)\b")


@dataclass(frozen=True)
class CommandResult:
    """The outcome of one GitHub CLI call, with its output captured."""

    exit_code: int
    stdout: str = ""
    stderr: str = ""

    @property
    def ok(self) -> bool:
        """Whether the call succeeded."""
        return self.exit_code == 0

    @property
    def output(self) -> str:
        """The captured output, so a warning can show why a call failed."""
        parts = [part.strip() for part in (self.stdout, self.stderr) if part and part.strip()]
        return " | ".join(parts)


Runner = Callable[[Sequence[str]], CommandResult]
Echo = Callable[[str], None]


def run_command(command: Sequence[str]) -> CommandResult:
    """Runs a command and captures its output."""
    completed = subprocess.run(
        list(command),
        capture_output=True,
        text=True,
        check=False,
    )
    return CommandResult(completed.returncode, completed.stdout, completed.stderr)


def echo(message: str) -> None:
    """Prints a progress message."""
    print(message)


def warn(message: str) -> None:
    """Prints a GitHub Actions warning annotation."""
    print(f"::warning::{message}")


@dataclass(frozen=True)
class MergeDecision:
    """What the merge gate decided for a review grade."""

    grade: str
    merge_ready: bool
    label_action: str

    @property
    def status_state(self) -> str:
        """The commit status state that records this decision."""
        return "success" if self.merge_ready else "neutral"

    @property
    def status_description(self) -> str:
        """The commit status description that records this decision."""
        if self.merge_ready:
            return f"GRADE={self.grade} merge-ready"
        return f"GRADE={self.grade or 'none'} needs a human merge"


def normalise_grade(grade: str | None) -> str:
    """Returns the canonical grade letter, or "" when there is none.

    The grades are matched exactly: anything the review parser did not
    produce (`A`, `B`, `C` or `D`) is no grade at all.
    """
    candidate = (grade or "").strip()
    return candidate if candidate in GRADES else ""


def decide(grade: str | None) -> MergeDecision:
    """Decides the merge gate outcome for a review grade. Fails closed.

    Only the exact grade `A` is merge-ready. Every other grade (`B`, `C`,
    `D`) and a missing grade hold the pull request and drop the
    `automerge` label.
    """
    normalised = normalise_grade(grade)
    if normalised == MERGE_GRADE:
        return MergeDecision(grade=normalised, merge_ready=True, label_action="add")
    return MergeDecision(grade=normalised, merge_ready=False, label_action="remove")


@dataclass(frozen=True)
class Action:
    """One GitHub action of the merge gate."""

    name: str
    command: tuple[str, ...]
    after: str | None = None
    best_effort: bool = False


@dataclass(frozen=True)
class ActionResult:
    """The outcome of one GitHub action of the merge gate."""

    name: str
    ok: bool
    output: str
    best_effort: bool = False

    @property
    def failed(self) -> bool:
        """Whether the action failed and had to be completed."""
        return not self.ok and not self.best_effort


def plan_actions(pr_number: str, grade: str | None) -> tuple[Action, ...]:
    """Returns the ordered GitHub actions the gate performs for a grade."""
    decision = decide(grade)
    if not decision.merge_ready:
        return (
            Action(
                name="remove_label",
                command=("gh", "pr", "edit", pr_number, "--remove-label", AUTOMERGE_LABEL),
            ),
        )
    return (
        Action(
            name="create_label",
            command=(
                "gh",
                "label",
                "create",
                AUTOMERGE_LABEL,
                "--description",
                LABEL_DESCRIPTION,
                "--color",
                LABEL_COLOR,
            ),
            # The label usually exists already; a failure here is not a
            # problem, so it must not raise a warning.
            best_effort=True,
        ),
        Action(
            name="add_label",
            command=("gh", "pr", "edit", pr_number, "--add-label", AUTOMERGE_LABEL),
        ),
        Action(
            name="approve",
            command=(
                "gh",
                "pr",
                "review",
                pr_number,
                "--approve",
                "--body",
                f"OpenCode v2 review grade: {decision.grade}. Approving per review policy.",
            ),
        ),
        Action(
            name="merge",
            command=("gh", "pr", "merge", pr_number, "--squash"),
        ),
        # The label is dropped again once the merge succeeded, so the
        # label-driven auto-merge workflow cannot merge the pull request a
        # second time with another merge method.
        Action(
            name="remove_label",
            command=("gh", "pr", "edit", pr_number, "--remove-label", AUTOMERGE_LABEL),
            after="merge",
        ),
    )


def execute_actions(
    actions: Sequence[Action],
    runner: Runner = run_command,
    echo: Echo = echo,
    warn: Echo = warn,
) -> list[ActionResult]:
    """Runs the actions in order and reports every failure with its output."""
    results: list[ActionResult] = []
    succeeded: set[str] = set()
    for action in actions:
        if action.after is not None and action.after not in succeeded:
            echo(f"Skipping '{action.name}': '{action.after}' did not succeed.")
            continue
        result = runner(action.command)
        if result.ok:
            succeeded.add(action.name)
        results.append(
            ActionResult(action.name, result.ok, result.output, action.best_effort)
        )
        if result.ok:
            echo(f"Ran '{action.name}'.")
        elif action.best_effort:
            echo(f"Skipped '{action.name}': {result.output}")
        else:
            warn(
                f"Could not run '{action.name}' "
                f"({' '.join(action.command)}): {result.output}"
            )
    return results


@dataclass(frozen=True)
class RecordedGrade:
    """The review grade recorded on a commit."""

    state: str
    description: str

    @property
    def grade(self) -> str:
        """The recorded grade letter, or "" when there is none.

        The status descriptions of a missing grade (`none`) and of a
        running review (`pending`) carry no grade letter, so they are
        reported as no grade at all.
        """
        match = GRADE_STATUS_PATTERN.match(self.description.strip())
        if match is None:
            return ""
        recorded = match.group(1)
        return recorded if recorded in GRADES else ""

    @property
    def merge_ready(self) -> bool:
        """Whether the recorded grade allows the pull request to be merged."""
        return self.state == "success" and self.grade == MERGE_GRADE


def resolve_repository(runner: Runner = run_command, override: str | None = None) -> str:
    """Returns the repository as `owner/name`."""
    if override:
        return override
    from_environment = os.environ.get("GITHUB_REPOSITORY", "").strip()
    if from_environment:
        return from_environment
    result = runner(("gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"))
    return result.stdout.strip() if result.ok else ""


def pr_labels(pr_number: str, runner: Runner = run_command) -> list[str] | None:
    """Returns the labels of a pull request, or None when they cannot be read."""
    result = runner(("gh", "pr", "view", pr_number, "--json", "labels", "--jq", ".labels[].name"))
    if not result.ok:
        return None
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def head_sha(pr_number: str, runner: Runner = run_command) -> str:
    """Returns the head commit of a pull request, or "" when unknown."""
    result = runner(("gh", "pr", "view", pr_number, "--json", "headRefOid", "--jq", ".headRefOid"))
    return result.stdout.strip() if result.ok else ""


def post_status(
    sha: str,
    state: str,
    description: str,
    repository: str,
    runner: Runner = run_command,
) -> CommandResult:
    """Records the review grade as a commit status on a commit."""
    return runner(
        (
            "gh",
            "api",
            "--method",
            "POST",
            f"repos/{repository}/statuses/{sha}",
            "-f",
            f"state={state}",
            "-f",
            f"context={REVIEW_STATUS_CONTEXT}",
            "-f",
            f"description={description}",
        )
    )


def read_status(sha: str, repository: str, runner: Runner = run_command) -> RecordedGrade:
    """Returns the review grade recorded on a commit."""
    result = runner(("gh", "api", f"repos/{repository}/commits/{sha}/status"))
    if not result.ok:
        return RecordedGrade("", "")
    try:
        payload = json.loads(result.stdout or "{}")
    except json.JSONDecodeError:
        return RecordedGrade("", "")
    statuses = [
        status
        for status in payload.get("statuses", [])
        if isinstance(status, dict) and status.get("context") == REVIEW_STATUS_CONTEXT
    ]
    if not statuses:
        return RecordedGrade("", "")
    latest = max(statuses, key=lambda status: (status.get("id") or 0, status.get("created_at") or ""))
    return RecordedGrade(str(latest.get("state") or ""), str(latest.get("description") or ""))


def remove_label(pr_number: str, runner: Runner = run_command) -> CommandResult:
    """Drops the `automerge` label of a pull request."""
    return runner(("gh", "pr", "edit", pr_number, "--remove-label", AUTOMERGE_LABEL))


def drop_automerge_label(
    pr_number: str,
    runner: Runner = run_command,
    echo: Echo = echo,
    warn: Echo = warn,
) -> bool:
    """Drops the `automerge` label of a pull request.

    Returns whether the label could be dropped.
    """
    removal = remove_label(pr_number, runner)
    if removal.ok:
        echo(f"Removed the '{AUTOMERGE_LABEL}' label.")
        return True
    warn(f"Could not remove the '{AUTOMERGE_LABEL}' label: {removal.output}")
    return False


def command_prepare(
    args: argparse.Namespace,
    runner: Runner = run_command,
    echo: Echo = echo,
    warn: Echo = warn,
) -> int:
    """Fails closed before the review runs.

    A label left over by an earlier run is dropped, and the head commit is
    marked as "review pending" so that a stale grade of the same commit
    cannot be reused.
    """
    repository = resolve_repository(runner, args.repo)
    labels = pr_labels(args.pr, runner)
    if labels is None:
        warn(
            "Could not read the labels of the pull request; the "
            f"'{AUTOMERGE_LABEL}' label cannot be ruled out. Refusing to "
            "review the pull request (fail closed)."
        )
        return 1
    if AUTOMERGE_LABEL in labels:
        removal = remove_label(args.pr, runner)
        if not removal.ok:
            warn(
                f"Could not remove the '{AUTOMERGE_LABEL}' label: {removal.output}. "
                "Refusing to review the pull request (fail closed)."
            )
            return 1
        echo(f"Removed the stale '{AUTOMERGE_LABEL}' label before the review.")
    sha = head_sha(args.pr, runner)
    if not sha:
        warn("Could not resolve the head commit; the pending review status was not recorded.")
        return 0
    status = post_status(sha, "neutral", PENDING_DESCRIPTION, repository, runner)
    if not status.ok:
        warn(f"Could not record the pending review status: {status.output}")
    else:
        echo(f"Recorded the pending review status on {sha[:7]}.")
    return 0


def gate_exit_code(
    decision: MergeDecision,
    results: Sequence[ActionResult],
    warn: Echo = warn,
) -> int:
    """Returns the exit code of the gate for the actions it ran.

    The gate fails when the merge it promised did not happen, or when the
    `automerge` label it had to drop is still there: both mean that the
    pull request must not be merged (fail closed).
    """
    if decision.merge_ready:
        merge = next((result for result in results if result.name == "merge"), None)
        if merge is None or not merge.ok:
            warn("The pull request was not merged by the gate (fail closed).")
            return 1
        return 0
    removal = next(
        (result for result in results if result.name == "remove_label"), None
    )
    if removal is None or not removal.ok:
        warn(
            f"The '{AUTOMERGE_LABEL}' label could not be dropped; the "
            "auto-merge workflow may still pick the pull request up "
            "(fail closed)."
        )
        return 1
    return 0


def command_gate(
    args: argparse.Namespace,
    runner: Runner = run_command,
    echo: Echo = echo,
    warn: Echo = warn,
) -> int:
    """Records the review grade and applies the merge gate.

    The grade belongs to the commit that was reviewed (`--reviewed-sha`):
    when the head commit of the pull request moved while the review ran,
    the grade is not recorded and nothing is merged (fail closed). The
    re-review that the new commit triggers decides then.
    """
    repository = resolve_repository(runner, args.repo)
    decision = decide(args.grade)
    echo(
        f"Grade {decision.grade or '<none>'}: "
        f"{'merge-ready' if decision.merge_ready else 'not merge-ready'}."
    )
    reviewed_sha = str(getattr(args, "reviewed_sha", "") or "").strip()
    sha = head_sha(args.pr, runner)
    if not sha:
        warn(
            "Could not resolve the head commit of the pull request; the "
            "review grade was not recorded and nothing was merged (fail closed)."
        )
        drop_automerge_label(args.pr, runner, echo, warn)
        return 1
    if reviewed_sha != sha:
        warn(
            f"The head commit moved while the review ran "
            f"({reviewed_sha[:7]} -> {sha[:7]}); the grade belongs to a commit "
            "that is no longer the head, so it was not recorded and nothing "
            "was merged (fail closed)."
        )
        drop_automerge_label(args.pr, runner, echo, warn)
        return 1
    status = post_status(
        sha,
        decision.status_state,
        decision.status_description,
        repository,
        runner,
    )
    if not status.ok:
        warn(f"Could not record the review grade: {status.output}")
    else:
        echo(f"Recorded the review grade on {sha[:7]}.")
    results = execute_actions(plan_actions(args.pr, args.grade), runner, echo, warn)
    failed = [result.name for result in results if result.failed]
    if failed:
        echo(f"The merge gate could not complete these steps: {', '.join(failed)}.")
    echo(f"decision={'merge' if decision.merge_ready else 'hold'}")
    return gate_exit_code(decision, results, warn)


def command_enforce(
    args: argparse.Namespace,
    runner: Runner = run_command,
    echo: Echo = echo,
    warn: Echo = warn,
) -> int:
    """Drops the `automerge` label from every pull request that is not merge-ready.

    A pull request is merge-ready only when a successful review recorded
    grade `A` for its current head commit. Every other pull request (a
    lower grade, a review that is still running, new commits after an `A`
    grade) loses the label, so the auto-merge workflow cannot merge it.
    """
    repository = resolve_repository(runner, args.repo)
    listing = runner(
        (
            "gh",
            "pr",
            "list",
            "--state",
            "open",
            "--label",
            AUTOMERGE_LABEL,
            "--json",
            "number,headRefOid",
        )
    )
    if not listing.ok:
        warn(
            f"Could not list the pull requests labelled '{AUTOMERGE_LABEL}': "
            f"{listing.output}. Refusing to merge anything (fail closed)."
        )
        return 1
    try:
        pull_requests = json.loads(listing.stdout or "[]")
    except json.JSONDecodeError:
        warn("Could not parse the pull request list. Refusing to merge anything (fail closed).")
        return 1
    failures = 0
    for pull_request in pull_requests:
        number = str(pull_request.get("number") or "")
        sha = str(pull_request.get("headRefOid") or "")
        if not number or not sha:
            warn("Skipping a pull request without a number or a head commit.")
            continue
        recorded = read_status(sha, repository, runner)
        if recorded.merge_ready:
            echo(
                f"PR #{number}: grade {recorded.grade} recorded for {sha[:7]}; "
                f"keeping the '{AUTOMERGE_LABEL}' label."
            )
            continue
        removal = remove_label(number, runner)
        if removal.ok:
            reason = recorded.description or "no review status"
            echo(
                f"PR #{number}: {reason}; removed the '{AUTOMERGE_LABEL}' label."
            )
        else:
            failures += 1
            warn(
                f"Could not remove the '{AUTOMERGE_LABEL}' label from PR #{number}: "
                f"{removal.output}"
            )
    if failures:
        warn(
            f"Could not drop the '{AUTOMERGE_LABEL}' label from {failures} pull "
            "request(s). Refusing to merge anything (fail closed)."
        )
        return 1
    return 0


def build_parser() -> argparse.ArgumentParser:
    """Builds the command line parser."""
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument(
        "--repo",
        help="The repository as owner/name (defaults to GITHUB_REPOSITORY or the checked-out repository).",
    )
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    prepare_parser = subparsers.add_parser(
        "prepare",
        parents=[common],
        help="Fails closed before the review runs.",
    )
    prepare_parser.add_argument("--pr", required=True, help="The pull request number.")

    gate_parser = subparsers.add_parser(
        "gate",
        parents=[common],
        help="Records the review grade and applies the merge gate.",
    )
    gate_parser.add_argument("--pr", required=True, help="The pull request number.")
    gate_parser.add_argument(
        "--grade",
        default="",
        help="The review grade (A, B, C or D). Everything else holds the pull request.",
    )
    gate_parser.add_argument(
        "--reviewed-sha",
        required=True,
        help=(
            "The commit that was reviewed. The gate refuses to record the "
            "grade when it is no longer the head commit of the pull request."
        ),
    )

    subparsers.add_parser(
        "enforce",
        parents=[common],
        help="Drops the automerge label from the pull requests that are not merge-ready.",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    commands = {
        "prepare": command_prepare,
        "gate": command_gate,
        "enforce": command_enforce,
    }
    return commands[args.command](args)


if __name__ == "__main__":
    raise SystemExit(main())
