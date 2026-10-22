"""Fixture tests for tool/review_merge_gate.py.

Run: python3 -m unittest tool.test_review_merge_gate -v
(or: python3 tool/test_review_merge_gate.py)
"""

import json
import unittest
from typing import Sequence

try:
    from review_merge_gate import (
        CommandResult,
        build_parser,
        command_enforce,
        command_gate,
        command_prepare,
        decide,
        execute_actions,
        plan_actions,
        read_status,
    )
except ImportError:  # `python -m unittest tool.test_...` from repo root.
    from tool.review_merge_gate import (
        CommandResult,
        build_parser,
        command_enforce,
        command_gate,
        command_prepare,
        decide,
        execute_actions,
        plan_actions,
        read_status,
    )


class FakeRunner:
    """Records the commands and replays canned results."""

    def __init__(self, results: dict[tuple[str, ...], CommandResult] | None = None) -> None:
        self.commands: list[tuple[str, ...]] = []
        self.results = results or {}

    def __call__(self, command: Sequence[str]) -> CommandResult:
        joined = " ".join(command)
        self.commands.append(tuple(command))
        for key, result in self.results.items():
            if all(fragment in joined for fragment in key):
                return result
        return CommandResult(0)

    def ran(self, *fragments: str) -> bool:
        """Whether a command containing every fragment was run."""
        return any(
            all(fragment in " ".join(command) for fragment in fragments)
            for command in self.commands
        )

    def index_of(self, *fragments: str) -> int:
        """The position of the first command containing every fragment."""
        for index, command in enumerate(self.commands):
            if all(fragment in " ".join(command) for fragment in fragments):
                return index
        raise AssertionError(f"No command matched {fragments}: {self.commands}")


def silent(message: str) -> None:
    """Swallows the progress messages of the merge gate."""
    return None


def parse(*arguments: str):
    """Builds the command line arguments of the merge gate."""
    return build_parser().parse_args(list(arguments))


class DecideTest(unittest.TestCase):
    def test_grade_a_is_merge_ready(self) -> None:
        decision = decide("A")

        self.assertTrue(decision.merge_ready)
        self.assertEqual(decision.label_action, "add")
        self.assertEqual(decision.status_state, "success")
        self.assertEqual(decision.status_description, "GRADE=A merge-ready")

    def test_lower_grades_are_not_merge_ready(self) -> None:
        for grade in ("B", "C", "D"):
            with self.subTest(grade=grade):
                decision = decide(grade)

                self.assertFalse(decision.merge_ready)
                self.assertEqual(decision.label_action, "remove")
                self.assertEqual(decision.status_state, "neutral")
                self.assertEqual(
                    decision.status_description,
                    f"GRADE={grade} needs a human merge",
                )

    def test_a_missing_or_unknown_grade_is_not_merge_ready(self) -> None:
        for grade in ("", "   ", None, "E", "a", "AA", "grade A"):
            with self.subTest(grade=grade):
                decision = decide(grade)

                self.assertFalse(decision.merge_ready)
                self.assertEqual(decision.label_action, "remove")
                self.assertEqual(decision.grade, "")
                self.assertEqual(
                    decision.status_description,
                    "GRADE=none needs a human merge",
                )


class PlanTest(unittest.TestCase):
    def test_grade_a_merges(self) -> None:
        names = [action.name for action in plan_actions("57", "A")]

        self.assertIn("merge", names)
        self.assertIn("add_label", names)

    def test_lower_grades_never_merge(self) -> None:
        for grade in ("B", "C", "D", ""):
            with self.subTest(grade=grade):
                names = [action.name for action in plan_actions("57", grade)]

                self.assertNotIn("merge", names)
                self.assertEqual(names, ["remove_label"])

    def test_the_merge_is_squashed(self) -> None:
        merge = next(
            action for action in plan_actions("57", "A") if action.name == "merge"
        )

        self.assertEqual(merge.command, ("gh", "pr", "merge", "57", "--squash"))

    def test_the_label_is_dropped_after_the_merge(self) -> None:
        removal = next(
            action for action in plan_actions("57", "A") if action.name == "remove_label"
        )

        self.assertEqual(
            removal.command,
            ("gh", "pr", "edit", "57", "--remove-label", "automerge"),
        )
        self.assertEqual(removal.after, "merge")


class ExecuteTest(unittest.TestCase):
    def test_a_non_a_grade_removes_the_automerge_label(self) -> None:
        runner = FakeRunner()

        execute_actions(plan_actions("57", "B"), runner, echo=silent)

        self.assertTrue(runner.ran("--remove-label", "automerge"))
        self.assertFalse(runner.ran("pr merge"))

    def test_grade_a_labels_approves_and_merges(self) -> None:
        runner = FakeRunner()

        execute_actions(plan_actions("57", "A"), runner, echo=silent, warn=silent)

        self.assertTrue(runner.ran("--add-label", "automerge"))
        self.assertTrue(runner.ran("pr review", "--approve"))
        self.assertTrue(runner.ran("pr merge", "--squash"))

    def test_the_label_is_kept_when_the_merge_failed(self) -> None:
        runner = FakeRunner({("pr merge",): CommandResult(1, "", "checks are running")})

        execute_actions(plan_actions("57", "A"), runner, echo=silent, warn=silent)

        self.assertFalse(runner.ran("--remove-label"))

    def test_a_failing_call_is_reported_with_its_captured_output(self) -> None:
        runner = FakeRunner(
            {("--remove-label",): CommandResult(1, "", "HTTP 404: label not found")}
        )
        warnings: list[str] = []

        execute_actions(plan_actions("57", "B"), runner, echo=silent, warn=warnings.append)

        self.assertEqual(len(warnings), 1)
        self.assertIn("HTTP 404: label not found", warnings[0])

    def test_an_existing_label_does_not_raise_a_warning(self) -> None:
        # `gh label create` fails when the label exists already, which is
        # the normal case.
        runner = FakeRunner(
            {("label create",): CommandResult(1, "", "label already exists")}
        )
        warnings: list[str] = []

        execute_actions(plan_actions("57", "A"), runner, echo=silent, warn=warnings.append)

        self.assertEqual(warnings, [])

    def test_the_results_report_the_failed_step(self) -> None:
        runner = FakeRunner({("pr merge",): CommandResult(1, "", "checks are running")})

        results = execute_actions(plan_actions("57", "A"), runner, echo=silent, warn=silent)

        failed = [result.name for result in results if result.failed]
        self.assertEqual(failed, ["merge"])

    def test_a_best_effort_step_is_not_a_failed_step(self) -> None:
        runner = FakeRunner(
            {("label create",): CommandResult(1, "", "label already exists")}
        )

        results = execute_actions(plan_actions("57", "A"), runner, echo=silent, warn=silent)

        failed = [result.name for result in results if result.failed]
        self.assertNotIn("create_label", failed)
        self.assertEqual(failed, [])


class RecordedGradeTest(unittest.TestCase):
    def _status(self, *statuses: dict[str, object]) -> FakeRunner:
        payload = {"statuses": list(statuses)}
        return FakeRunner({("commits/",): CommandResult(0, json.dumps(payload))})

    def test_the_latest_grade_decides(self) -> None:
        runner = self._status(
            {
                "id": 1,
                "context": "opencode-review-grade",
                "state": "neutral",
                "description": "GRADE=B needs a human merge",
            },
            {
                "id": 2,
                "context": "opencode-review-grade",
                "state": "success",
                "description": "GRADE=A merge-ready",
            },
            {
                "id": 3,
                "context": "another-check",
                "state": "success",
                "description": "unrelated",
            },
        )

        recorded = read_status("abc1234", "owner/name", runner)

        self.assertEqual(recorded.grade, "A")
        self.assertTrue(recorded.merge_ready)

    def test_a_pending_review_is_not_merge_ready(self) -> None:
        runner = self._status(
            {
                "id": 1,
                "context": "opencode-review-grade",
                "state": "neutral",
                "description": "GRADE=pending review in progress",
            }
        )

        recorded = read_status("abc1234", "owner/name", runner)

        self.assertEqual(recorded.grade, "")
        self.assertFalse(recorded.merge_ready)

    def test_a_lower_grade_is_not_merge_ready(self) -> None:
        runner = self._status(
            {
                "id": 1,
                "context": "opencode-review-grade",
                "state": "neutral",
                "description": "GRADE=C needs a human merge",
            }
        )

        recorded = read_status("abc1234", "owner/name", runner)

        self.assertEqual(recorded.grade, "C")
        self.assertFalse(recorded.merge_ready)

    def test_a_missing_grade_is_not_merge_ready(self) -> None:
        runner = self._status(
            {
                "id": 1,
                "context": "opencode-review-grade",
                "state": "neutral",
                "description": "GRADE=none needs a human merge",
            }
        )

        recorded = read_status("abc1234", "owner/name", runner)

        self.assertEqual(recorded.grade, "")
        self.assertFalse(recorded.merge_ready)

    def test_a_missing_status_is_not_merge_ready(self) -> None:
        runner = self._status()

        recorded = read_status("abc1234", "owner/name", runner)

        self.assertEqual(recorded.grade, "")
        self.assertFalse(recorded.merge_ready)

    def test_a_failed_read_is_not_merge_ready(self) -> None:
        runner = FakeRunner({("commits/",): CommandResult(1, "", "HTTP 500")})

        recorded = read_status("abc1234", "owner/name", runner)

        self.assertFalse(recorded.merge_ready)


class PrepareTest(unittest.TestCase):
    def test_a_stale_label_is_removed_before_the_review(self) -> None:
        runner = FakeRunner(
            {("pr view", "labels"): CommandResult(0, "automerge\nbug\n")}
        )

        exit_code = command_prepare(
            parse("prepare", "--pr", "57", "--repo", "owner/name"),
            runner=runner,
            echo=silent,
            warn=silent,
        )

        self.assertEqual(exit_code, 0)
        self.assertTrue(runner.ran("--remove-label", "automerge"))

    def test_the_review_is_refused_when_the_label_cannot_be_removed(self) -> None:
        runner = FakeRunner(
            {
                ("pr view", "labels"): CommandResult(0, "automerge\n"),
                ("--remove-label",): CommandResult(1, "", "HTTP 403"),
            }
        )
        warnings: list[str] = []

        exit_code = command_prepare(
            parse("prepare", "--pr", "57", "--repo", "owner/name"),
            runner=runner,
            echo=silent,
            warn=warnings.append,
        )

        self.assertEqual(exit_code, 1)
        self.assertIn("HTTP 403", warnings[0])

    def test_the_pending_review_is_recorded_on_the_head_commit(self) -> None:
        runner = FakeRunner(
            {("pr view", "headRefOid"): CommandResult(0, "abc1234\n")}
        )

        exit_code = command_prepare(
            parse("prepare", "--pr", "57", "--repo", "owner/name"),
            runner=runner,
            echo=silent,
            warn=silent,
        )

        self.assertEqual(exit_code, 0)
        self.assertTrue(
            runner.ran(
                "statuses/abc1234",
                "state=neutral",
                "GRADE=pending review in progress",
            )
        )

    def test_nothing_happens_without_a_stale_label(self) -> None:
        runner = FakeRunner(
            {("pr view", "labels"): CommandResult(0, "bug\ndocumentation\n")}
        )

        exit_code = command_prepare(
            parse("prepare", "--pr", "57", "--repo", "owner/name"),
            runner=runner,
            echo=silent,
            warn=silent,
        )

        self.assertEqual(exit_code, 0)
        self.assertFalse(runner.ran("--remove-label"))


class GateTest(unittest.TestCase):
    def _runner(self) -> FakeRunner:
        return FakeRunner({("pr view", "headRefOid"): CommandResult(0, "abc1234\n")})

    def test_grade_a_records_the_grade_and_merges(self) -> None:
        runner = self._runner()

        exit_code = command_gate(
            parse(
                "gate",
                "--pr",
                "57",
                "--grade",
                "A",
                "--reviewed-sha",
                "abc1234",
                "--repo",
                "owner/name",
            ),
            runner=runner,
            echo=silent,
            warn=silent,
        )

        self.assertEqual(exit_code, 0)
        self.assertTrue(
            runner.ran("statuses/abc1234", "state=success", "GRADE=A merge-ready")
        )
        self.assertTrue(runner.ran("pr merge", "--squash"))

    def test_the_grade_is_recorded_before_the_label_is_added(self) -> None:
        # The auto-merge workflow trusts the recorded grade, so the label
        # must never show up before the grade is recorded.
        runner = self._runner()

        command_gate(
            parse(
                "gate",
                "--pr",
                "57",
                "--grade",
                "A",
                "--reviewed-sha",
                "abc1234",
                "--repo",
                "owner/name",
            ),
            runner=runner,
            echo=silent,
            warn=silent,
        )

        self.assertLess(
            runner.index_of("statuses/abc1234"),
            runner.index_of("--add-label"),
        )

    def test_a_lower_grade_holds_the_pull_request(self) -> None:
        runner = self._runner()

        exit_code = command_gate(
            parse(
                "gate",
                "--pr",
                "57",
                "--grade",
                "B",
                "--reviewed-sha",
                "abc1234",
                "--repo",
                "owner/name",
            ),
            runner=runner,
            echo=silent,
            warn=silent,
        )

        self.assertEqual(exit_code, 0)
        self.assertFalse(runner.ran("pr merge"))
        self.assertFalse(runner.ran("--add-label"))
        self.assertTrue(runner.ran("--remove-label", "automerge"))
        self.assertTrue(
            runner.ran("statuses/abc1234", "state=neutral", "GRADE=B needs a human merge")
        )

    def test_a_missing_grade_holds_the_pull_request(self) -> None:
        runner = self._runner()

        exit_code = command_gate(
            parse(
                "gate",
                "--pr",
                "57",
                "--reviewed-sha",
                "abc1234",
                "--repo",
                "owner/name",
            ),
            runner=runner,
            echo=silent,
            warn=silent,
        )

        self.assertEqual(exit_code, 0)
        self.assertFalse(runner.ran("pr merge"))
        self.assertTrue(runner.ran("--remove-label", "automerge"))
        self.assertTrue(runner.ran("statuses/abc1234", "GRADE=none needs a human merge"))

    def test_a_moved_head_commit_is_not_graded_and_not_merged(self) -> None:
        # The pull request received a commit while the review ran: the
        # grade belongs to the reviewed commit and must not be applied to
        # the new head commit.
        runner = self._runner()
        warnings: list[str] = []

        exit_code = command_gate(
            parse(
                "gate",
                "--pr",
                "57",
                "--grade",
                "A",
                "--reviewed-sha",
                "old1234",
                "--repo",
                "owner/name",
            ),
            runner=runner,
            echo=silent,
            warn=warnings.append,
        )

        self.assertEqual(exit_code, 1)
        self.assertFalse(runner.ran("statuses/"))
        self.assertFalse(runner.ran("pr merge"))
        self.assertFalse(runner.ran("--add-label"))
        self.assertTrue(runner.ran("--remove-label", "automerge"))
        self.assertTrue(any("head commit moved" in warning for warning in warnings))

    def test_an_unresolved_head_commit_is_not_graded_and_not_merged(self) -> None:
        runner = FakeRunner({("pr view", "headRefOid"): CommandResult(1, "", "HTTP 500")})
        warnings: list[str] = []

        exit_code = command_gate(
            parse(
                "gate",
                "--pr",
                "57",
                "--grade",
                "A",
                "--reviewed-sha",
                "abc1234",
                "--repo",
                "owner/name",
            ),
            runner=runner,
            echo=silent,
            warn=warnings.append,
        )

        self.assertEqual(exit_code, 1)
        self.assertFalse(runner.ran("statuses/"))
        self.assertFalse(runner.ran("pr merge"))
        self.assertFalse(runner.ran("--add-label"))
        self.assertTrue(runner.ran("--remove-label", "automerge"))
        self.assertTrue(any("head commit" in warning for warning in warnings))

    def test_a_failed_merge_is_reported(self) -> None:
        runner = FakeRunner(
            {
                ("pr view", "headRefOid"): CommandResult(0, "abc1234\n"),
                ("pr merge",): CommandResult(1, "", "checks are running"),
            }
        )
        messages: list[str] = []

        exit_code = command_gate(
            parse(
                "gate",
                "--pr",
                "57",
                "--grade",
                "A",
                "--reviewed-sha",
                "abc1234",
                "--repo",
                "owner/name",
            ),
            runner=runner,
            echo=messages.append,
            warn=silent,
        )

        self.assertEqual(exit_code, 1)
        self.assertTrue(
            any(
                "could not complete" in message and "merge" in message
                for message in messages
            )
        )

    def test_a_failed_label_removal_is_reported(self) -> None:
        runner = FakeRunner(
            {
                ("pr view", "headRefOid"): CommandResult(0, "abc1234\n"),
                ("--remove-label",): CommandResult(1, "", "HTTP 403"),
            }
        )
        messages: list[str] = []

        exit_code = command_gate(
            parse(
                "gate",
                "--pr",
                "57",
                "--grade",
                "B",
                "--reviewed-sha",
                "abc1234",
                "--repo",
                "owner/name",
            ),
            runner=runner,
            echo=messages.append,
            warn=silent,
        )

        self.assertEqual(exit_code, 1)
        self.assertTrue(
            any(
                "could not complete" in message and "remove_label" in message
                for message in messages
            )
        )


class EnforceTest(unittest.TestCase):
    GRADE_A_STATUS = {
        "id": 1,
        "context": "opencode-review-grade",
        "state": "success",
        "description": "GRADE=A merge-ready",
    }

    def _runner(
        self,
        head: str = "abc1234",
        statuses: list[dict[str, object]] | None = None,
    ) -> FakeRunner:
        listing = json.dumps([{"number": 57, "headRefOid": head}])
        payload = {"statuses": statuses if statuses is not None else []}
        return FakeRunner(
            {
                ("pr list",): CommandResult(0, listing),
                (f"commits/{head}",): CommandResult(0, json.dumps(payload)),
            }
        )

    def test_the_label_is_removed_when_no_grade_is_recorded(self) -> None:
        runner = self._runner()

        exit_code = command_enforce(
            parse("enforce", "--repo", "owner/name"),
            runner=runner,
            echo=silent,
            warn=silent,
        )

        self.assertEqual(exit_code, 0)
        self.assertTrue(runner.ran("--remove-label", "automerge"))

    def test_the_label_is_removed_after_new_commits(self) -> None:
        # The grade was recorded for the previous head commit, so the pull
        # request is not merge-ready anymore.
        runner = FakeRunner(
            {
                ("pr list",): CommandResult(
                    0,
                    json.dumps([{"number": 57, "headRefOid": "def5678"}]),
                ),
                ("commits/def5678",): CommandResult(0, json.dumps({"statuses": []})),
            }
        )

        exit_code = command_enforce(
            parse("enforce", "--repo", "owner/name"),
            runner=runner,
            echo=silent,
            warn=silent,
        )

        self.assertEqual(exit_code, 0)
        self.assertTrue(runner.ran("--remove-label", "automerge"))

    def test_the_label_is_kept_when_grade_a_is_recorded(self) -> None:
        runner = self._runner(statuses=[self.GRADE_A_STATUS])

        exit_code = command_enforce(
            parse("enforce", "--repo", "owner/name"),
            runner=runner,
            echo=silent,
            warn=silent,
        )

        self.assertEqual(exit_code, 0)
        self.assertFalse(runner.ran("--remove-label"))

    def test_a_failed_listing_merges_nothing(self) -> None:
        runner = FakeRunner({("pr list",): CommandResult(1, "", "HTTP 500")})
        warnings: list[str] = []

        exit_code = command_enforce(
            parse("enforce", "--repo", "owner/name"),
            runner=runner,
            echo=silent,
            warn=warnings.append,
        )

        self.assertEqual(exit_code, 1)
        self.assertIn("HTTP 500", warnings[0])

    def test_a_failed_label_removal_merges_nothing(self) -> None:
        runner = FakeRunner(
            {
                ("pr list",): CommandResult(
                    0,
                    json.dumps([{"number": 57, "headRefOid": "abc1234"}]),
                ),
                ("commits/",): CommandResult(0, json.dumps({"statuses": []})),
                ("--remove-label",): CommandResult(1, "", "HTTP 403"),
            }
        )
        warnings: list[str] = []

        exit_code = command_enforce(
            parse("enforce", "--repo", "owner/name"),
            runner=runner,
            echo=silent,
            warn=warnings.append,
        )

        self.assertEqual(exit_code, 1)
        self.assertIn("HTTP 403", warnings[0])


if __name__ == "__main__":
    unittest.main()
