"""Fetches and prepares the Bakehub task that BakeAgent executes.

Bakehub keeps the tasks of a repository/branch and exposes them through a
Supabase edge function. A task with reviewer feedback (a change requested on
an open pull request) takes priority over a new pending task, exactly like
`.devcontainer/bakehub-setup.sh` does in the devcontainer.

The workflow and the devcontainer share this script, so the task selection,
the OpenCode prompt and the branch slug cannot drift between them.

Usage:
  # Print the next task as JSON (`null` when nothing is pending).
  python3 tool/bakehub_tasks.py select --output .bakeagent/task.json

  # Same shape, for a manual run that does not call the API.
  python3 tool/bakehub_tasks.py manual --title "Fix the login crash" \\
      --description "It crashes on iOS" --output .bakeagent/task.json

  # Print the OpenCode prompt for a task.
  python3 tool/bakehub_tasks.py prompt --task .bakeagent/task.json

  # Print `$GITHUB_OUTPUT` lines for a task (`has_task=false` when empty).
  python3 tool/bakehub_tasks.py outputs --task .bakeagent/task.json

  # Branch-safe slug for a task title.
  python3 tool/bakehub_tasks.py slug --title "Fix the login crash"

  # Tell Bakehub that a feedback task was handled.
  python3 tool/bakehub_tasks.py clear-feedback --task-id <id>

Environment:
  BAKEHUB_API_KEY   API key (x-api-key). Required by `select`/`clear-feedback`.
  BAKEHUB_API_URL   API base URL. Defaults to the project endpoint.
  REPOSITORY_NAME   `owner/name`. Defaults to the checkout's origin remote.
  BRANCH_NAME       Branch to ask for. Defaults to `main`.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from typing import Any, Mapping, Sequence

DEFAULT_API_URL = "https://ajfjzspcfmryesrkxuca.supabase.co/functions/v1/api"
DEFAULT_BRANCH = "main"
GITHUB_REMOTE_PATTERN = re.compile(
    r"github\.com[:/]+(?P<repository>[^/\s]+/[^/\s]+?)(?:\.git)?/?$"
)
SLUG_PATTERN = re.compile(r"[^a-z0-9]+")


class BakehubError(RuntimeError):
    """A task could not be fetched or prepared."""


@dataclass(frozen=True)
class Task:
    """One Bakehub task (a pending task or a pull request feedback item)."""

    id: str
    title: str
    description: str
    feedback: str
    status: str

    @property
    def kind(self) -> str:
        """`feedback` for a review change request, `pending` otherwise."""
        return "feedback" if self.feedback else "pending"

    def as_json(self) -> dict[str, str]:
        """The task as it is written to `.bakeagent/task.json`."""
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "feedback": self.feedback,
            "status": self.status,
            "kind": self.kind,
        }


def normalise_tasks(payload: Any) -> list[Task]:
    """Returns the tasks of a Bakehub response.

    Both shapes the API answers with are accepted (`{"tasks": [...]}` and a
    bare list). Anything else is an error: a malformed response must not be
    mistaken for "no pending tasks".
    """
    if isinstance(payload, Mapping):
        items = payload.get("tasks")
    else:
        items = payload
    if not isinstance(items, list):
        raise BakehubError("Unexpected Bakehub response: expected a list of tasks.")
    tasks: list[Task] = []
    for item in items:
        if not isinstance(item, Mapping):
            raise BakehubError("Unexpected Bakehub response: a task is not an object.")
        fields = {
            key: _text(item.get(key))
            for key in ("id", "title", "description", "feedback", "status")
        }
        if not fields["id"] and not fields["title"]:
            # A row without an id and a title cannot be run or reported back.
            continue
        tasks.append(Task(**fields))
    return tasks


def select_task(tasks: Sequence[Task]) -> Task | None:
    """Returns the task to run: feedback first, then the first pending one."""
    for task in tasks:
        if task.feedback:
            return task
    for task in tasks:
        if task.status == "pending":
            return task
    return None


def slugify(title: str, limit: int = 40) -> str:
    """Returns a branch-safe slug (`fix-the-login-crash`)."""
    slug = SLUG_PATTERN.sub("-", title.strip().lower()).strip("-")
    slug = slug[:limit].rstrip("-")
    return slug or "task"


def build_prompt(task: Task) -> str:
    """Returns the OpenCode prompt for a task.

    The agent runs inside the dev container image while the workflow keeps git:
    it commits, pushes and opens the pull request after the verification gate.
    The agent must not touch git or GitHub, and it never receives a token.
    """
    lines = [f"Task: {task.title}", ""]
    if task.description:
        lines.extend([task.description, ""])
    if task.feedback:
        lines.extend(
            [
                "A pull request is already open for this work. Address this",
                "reviewer feedback:",
                "",
                task.feedback,
                "",
            ]
        )
    lines.extend(
        [
            "Rules:",
            "- Work only inside this repository's working tree.",
            "- Follow AGENTS.md: feature-first packages, Cubit states, no",
            "  hardcoded user-visible strings, no fake data on failure.",
            "- Keep the change small and finish it; do not leave TODOs.",
            "- Run `flutter analyze` and `flutter test` and fix what you break.",
            "- Do NOT run `git commit`, `git push` or `gh`: the workflow",
            "  commits and opens the pull request after its own checks.",
        ]
    )
    return "\n".join(lines) + "\n"


def github_outputs(task: Task | None) -> str:
    """Returns the `$GITHUB_OUTPUT` lines for a task.

    Every value is collapsed to one line: `$GITHUB_OUTPUT` is line based, so
    a newline inside a task field would be read as another output (or as an
    injected one). A task title is also a commit subject, which must stay on
    a single line.
    """
    if task is None:
        return "has_task=false\n"
    outputs = {
        "has_task": "true",
        "task_id": task.id,
        "task_kind": task.kind,
        "task_title": task.title,
    }
    return "".join(f"{key}={_single_line(value)}\n" for key, value in outputs.items())


def repository_from_remote(url: str) -> str:
    """Returns `owner/name` for a GitHub remote URL, or "" when unknown."""
    match = GITHUB_REMOTE_PATTERN.search(url.strip())
    return match.group("repository") if match else ""


def fetch_tasks(
    api_url: str,
    api_key: str,
    repository: str,
    branch: str,
    timeout: float = 30.0,
) -> list[Task]:
    """Fetches the tasks of a repository/branch from the Bakehub API."""
    if not api_key:
        raise BakehubError("BAKEHUB_API_KEY is not set; cannot read the Bakehub tasks.")
    if not repository:
        raise BakehubError("Could not resolve the repository (owner/name).")
    query = urllib.parse.urlencode(
        {
            "action": "get-pending-tasks",
            "repository_name": repository,
            "branch_name": branch,
        }
    )
    request = urllib.request.Request(
        f"{api_url}?{query}",
        headers={"x-api-key": api_key, "Accept": "application/json"},
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            payload = json.load(response)
    except (
        urllib.error.URLError,
        TimeoutError,
        OSError,
        json.JSONDecodeError,
    ) as error:
        raise BakehubError(f"Could not read the Bakehub tasks: {error}") from error
    return normalise_tasks(payload)


def clear_feedback(
    api_url: str, api_key: str, task_id: str, timeout: float = 30.0
) -> None:
    """Tells Bakehub that the feedback of a task was handled."""
    if not api_key:
        raise BakehubError(
            "BAKEHUB_API_KEY is not set; cannot clear the task feedback."
        )
    request = urllib.request.Request(
        f"{api_url}?action=clear-task-feedback",
        data=json.dumps({"task_id": task_id}).encode(),
        headers={
            "x-api-key": api_key,
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout):
            return
    except (urllib.error.URLError, TimeoutError, OSError) as error:
        raise BakehubError(
            f"Could not clear the feedback of task {task_id}: {error}"
        ) from error


def _text(value: Any) -> str:
    """Returns a trimmed string for a JSON field, never a fallback value."""
    if value is None:
        return ""
    return str(value).strip()


def _single_line(value: str) -> str:
    """Collapses every whitespace run (newlines included) into one space."""
    return " ".join(value.split())


def _load_task(path: str) -> Task | None:
    """Reads `.bakeagent/task.json`, which is empty or `null` when there is none."""
    try:
        with open(path, encoding="utf-8") as handle:
            payload = json.load(handle)
    except (OSError, json.JSONDecodeError) as error:
        raise BakehubError(f"Could not read the task file {path}: {error}") from error
    if payload is None:
        return None
    if not isinstance(payload, Mapping):
        raise BakehubError(f"Unexpected task file {path}: expected an object or null.")
    fields = {
        key: _text(payload.get(key))
        for key in ("id", "title", "description", "feedback", "status")
    }
    if not fields["id"] and not fields["title"]:
        raise BakehubError(f"Unexpected task file {path}: no id and no title.")
    return Task(**fields)


def _write(path: str | None, text: str) -> None:
    """Writes `text` to `path`, or prints it when no path was given."""
    if path is None:
        sys.stdout.write(text)
        return
    directory = os.path.dirname(path)
    if directory:
        os.makedirs(directory, exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(text)


def _git(*arguments: str) -> str:
    """Runs git and returns its trimmed output, or "" when it fails."""
    try:
        result = subprocess.run(
            ("git", *arguments), capture_output=True, text=True, check=False
        )
    except OSError:
        return ""
    return result.stdout.strip() if result.returncode == 0 else ""


def _repository() -> str:
    """Returns the repository of the checkout (`owner/name`)."""
    from_environment = os.environ.get("REPOSITORY_NAME", "").strip()
    if from_environment:
        return from_environment
    return repository_from_remote(_git("remote", "get-url", "origin"))


def _branch() -> str:
    """Returns the branch to ask tasks for."""
    from_environment = os.environ.get("BRANCH_NAME", "").strip()
    if from_environment:
        return from_environment
    current = _git("rev-parse", "--abbrev-ref", "HEAD")
    return current if current and current != "HEAD" else DEFAULT_BRANCH


def _api_url() -> str:
    """Returns the Bakehub API base URL."""
    return os.environ.get("BAKEHUB_API_URL", "").strip() or DEFAULT_API_URL


def _api_key() -> str:
    """Returns the Bakehub API key."""
    return os.environ.get("BAKEHUB_API_KEY", "").strip()


def command_select(args: argparse.Namespace) -> int:
    """Writes the next task as JSON (`null` when nothing is pending)."""
    task = select_task(fetch_tasks(_api_url(), _api_key(), _repository(), _branch()))
    _write(args.output, json.dumps(task.as_json() if task else None, indent=2) + "\n")
    if task is None:
        print("No pending Bakehub task.")
    else:
        print(f"Selected task {task.id or '<no id>'} ({task.kind}): {task.title}")
    return 0


def command_manual(args: argparse.Namespace) -> int:
    """Writes a task built from workflow inputs (no API call)."""
    title = args.title.strip()
    if not title:
        raise BakehubError("A manual task needs a title.")
    task = Task(
        id=args.id.strip(),
        title=title,
        description=args.description.strip(),
        feedback="",
        status="pending",
    )
    _write(args.output, json.dumps(task.as_json(), indent=2) + "\n")
    print(f"Using the manual task: {task.title}")
    return 0


def command_prompt(args: argparse.Namespace) -> int:
    """Prints the OpenCode prompt of a task."""
    task = _load_task(args.task)
    if task is None:
        raise BakehubError(f"The task file {args.task} does not contain a task.")
    sys.stdout.write(build_prompt(task))
    return 0


def command_outputs(args: argparse.Namespace) -> int:
    """Prints the `$GITHUB_OUTPUT` lines of a task file."""
    sys.stdout.write(github_outputs(_load_task(args.task)))
    return 0


def command_slug(args: argparse.Namespace) -> int:
    """Prints the branch slug of a task title."""
    print(slugify(args.title))
    return 0


def command_clear_feedback(args: argparse.Namespace) -> int:
    """Clears the feedback flag of a handled task."""
    clear_feedback(_api_url(), _api_key(), args.task_id)
    print(f"Cleared the feedback of task {args.task_id}.")
    return 0


def build_parser() -> argparse.ArgumentParser:
    """Builds the command line parser."""
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    select_parser = subparsers.add_parser(
        "select", help="Writes the next Bakehub task as JSON."
    )
    select_parser.add_argument("--output", help="Write to this file instead of stdout.")
    select_parser.set_defaults(handler=command_select)

    manual_parser = subparsers.add_parser(
        "manual", help="Writes a task from manual inputs."
    )
    manual_parser.add_argument("--title", required=True, help="The task title.")
    manual_parser.add_argument(
        "--description", default="", help="The task description."
    )
    manual_parser.add_argument("--id", default="", help="An optional task id.")
    manual_parser.add_argument("--output", help="Write to this file instead of stdout.")
    manual_parser.set_defaults(handler=command_manual)

    prompt_parser = subparsers.add_parser(
        "prompt", help="Prints the OpenCode prompt of a task."
    )
    prompt_parser.add_argument("--task", required=True, help="The task JSON file.")
    prompt_parser.set_defaults(handler=command_prompt)

    outputs_parser = subparsers.add_parser(
        "outputs", help="Prints $GITHUB_OUTPUT lines."
    )
    outputs_parser.add_argument("--task", required=True, help="The task JSON file.")
    outputs_parser.set_defaults(handler=command_outputs)

    slug_parser = subparsers.add_parser("slug", help="Prints a branch-safe slug.")
    slug_parser.add_argument("--title", required=True, help="The task title.")
    slug_parser.set_defaults(handler=command_slug)

    feedback_parser = subparsers.add_parser(
        "clear-feedback", help="Clears the feedback flag of a handled task."
    )
    feedback_parser.add_argument(
        "--task-id", required=True, help="The Bakehub task id."
    )
    feedback_parser.set_defaults(handler=command_clear_feedback)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        return args.handler(args)
    except BakehubError as error:
        print(f"::error::{error}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
