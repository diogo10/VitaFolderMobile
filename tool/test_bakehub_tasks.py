"""Fixture tests for tool/bakehub_tasks.py.

Run: python3 -m unittest tool.test_bakehub_tasks -v
(or: python3 tool/test_bakehub_tasks.py)
"""

import io
import json
import os
import tempfile
import unittest
from contextlib import redirect_stdout

try:
    from bakehub_tasks import (
        BakehubError,
        Task,
        build_prompt,
        github_outputs,
        main,
        normalise_tasks,
        repository_from_remote,
        select_task,
        slugify,
    )
except ImportError:  # `python -m unittest tool.test_...` from repo root.
    from tool.bakehub_tasks import (
        BakehubError,
        Task,
        build_prompt,
        github_outputs,
        main,
        normalise_tasks,
        repository_from_remote,
        select_task,
        slugify,
    )


def make_task(**overrides: str) -> Task:
    """Returns a task with sensible defaults for the tests."""
    fields = {
        "id": "task-1",
        "title": "Fix the login crash",
        "description": "It crashes on iOS",
        "feedback": "",
        "status": "pending",
    }
    fields.update(overrides)
    return Task(**fields)


class NormaliseTasksTest(unittest.TestCase):
    def test_reads_both_payload_shapes(self) -> None:
        row = {
            "id": "t1",
            "title": "A task",
            "description": "d",
            "feedback": "",
            "status": "pending",
        }
        for payload in ({"tasks": [row]}, [row]):
            tasks = normalise_tasks(payload)
            self.assertEqual(len(tasks), 1)
            self.assertEqual(tasks[0].title, "A task")

    def test_reads_the_improvement_payload(self) -> None:
        # bakehub-setup.sh accepts `(.tasks // .)`, so `tasks` is optional.
        row = {"id": "t1", "title": "A task", "status": "pending"}
        self.assertEqual(normalise_tasks([row])[0].id, "t1")

    def test_rejects_malformed_payloads(self) -> None:
        for payload in (None, 42, "tasks", {"tasks": "nope"}, [42]):
            with self.subTest(payload=payload):
                with self.assertRaises(BakehubError):
                    normalise_tasks(payload)

    def test_skips_rows_without_id_and_title(self) -> None:
        payload = {"tasks": [{"status": "pending"}, {"id": "t2", "title": "Real"}]}
        self.assertEqual([task.id for task in normalise_tasks(payload)], ["t2"])

    def test_trims_fields_and_normalises_nulls(self) -> None:
        payload = {"tasks": [{"id": " t1 ", "title": " T ", "feedback": None}]}
        task = normalise_tasks(payload)[0]
        self.assertEqual((task.id, task.title, task.feedback), ("t1", "T", ""))


class SelectTaskTest(unittest.TestCase):
    def test_feedback_has_priority(self) -> None:
        tasks = [
            make_task(id="pending-1"),
            make_task(id="feedback-1", feedback="Please rename this"),
        ]
        chosen = select_task(tasks)
        self.assertIsNotNone(chosen)
        self.assertEqual(chosen.id, "feedback-1")
        self.assertEqual(chosen.kind, "feedback")

    def test_returns_the_first_pending_task(self) -> None:
        tasks = [
            make_task(id="done", status="done"),
            make_task(id="pending-1"),
            make_task(id="pending-2"),
        ]
        chosen = select_task(tasks)
        self.assertIsNotNone(chosen)
        self.assertEqual(chosen.id, "pending-1")

    def test_returns_none_when_nothing_is_pending(self) -> None:
        self.assertIsNone(select_task([]))
        self.assertIsNone(select_task([make_task(status="done")]))


class SlugifyTest(unittest.TestCase):
    def test_builds_a_branch_safe_slug(self) -> None:
        self.assertEqual(slugify("Fix the login crash!"), "fix-the-login-crash")
        self.assertEqual(slugify("  A/B: c_d  "), "a-b-c-d")

    def test_truncates_without_a_trailing_dash(self) -> None:
        slug = slugify("a" * 30 + " " + "b" * 30)
        self.assertLessEqual(len(slug), 40)
        self.assertFalse(slug.endswith("-"))

    def test_empty_titles_get_a_stable_slug(self) -> None:
        self.assertEqual(slugify(""), "task")
        self.assertEqual(slugify("!!!"), "task")


class BuildPromptTest(unittest.TestCase):
    def test_prompt_carries_the_task_and_keeps_git_with_the_workflow(self) -> None:
        prompt = build_prompt(make_task())
        self.assertIn("Fix the login crash", prompt)
        self.assertIn("It crashes on iOS", prompt)
        self.assertIn("Do NOT run `git commit`", prompt)
        self.assertNotIn("codespace", prompt)

    def test_feedback_is_included(self) -> None:
        task = make_task(feedback="The dialog text is hardcoded")
        self.assertIn("The dialog text is hardcoded", build_prompt(task))


class GithubOutputsTest(unittest.TestCase):
    def test_no_task(self) -> None:
        self.assertEqual(github_outputs(None), "has_task=false\n")

    def test_single_line_values(self) -> None:
        outputs = github_outputs(make_task(title="Fix  the\ncrash"))
        self.assertIn("has_task=true\n", outputs)
        self.assertIn("task_id=task-1\n", outputs)
        self.assertIn("task_kind=pending\n", outputs)
        # A title is a commit subject: it must stay on one line.
        self.assertIn("task_title=Fix the crash\n", outputs)

    def test_values_cannot_inject_another_output(self) -> None:
        # `$GITHUB_OUTPUT` is line based: a newline in a field would be read
        # as a second output line, so every value is collapsed.
        outputs = github_outputs(make_task(id="t1\ntask_kind=feedback", title="a\nb"))
        self.assertIn("task_id=t1 task_kind=feedback\n", outputs)
        self.assertIn("task_title=a b\n", outputs)
        self.assertEqual(len(outputs.splitlines()), 4)


class RepositoryFromRemoteTest(unittest.TestCase):
    def test_github_remote_urls(self) -> None:
        self.assertEqual(
            repository_from_remote("git@github.com:diogo10/VitaFolderMobile.git"),
            "diogo10/VitaFolderMobile",
        )
        self.assertEqual(
            repository_from_remote("https://github.com/diogo10/VitaFolderMobile.git"),
            "diogo10/VitaFolderMobile",
        )
        self.assertEqual(
            repository_from_remote("https://github.com/diogo10/VitaFolderMobile"),
            "diogo10/VitaFolderMobile",
        )

    def test_other_remotes_are_unknown(self) -> None:
        self.assertEqual(repository_from_remote("git@gitlab.com:o/r.git"), "")


class CommandLineTest(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.task_path = os.path.join(self.directory.name, "task.json")

    def run_main(self, *arguments: str) -> str:
        stdout = io.StringIO()
        with redirect_stdout(stdout):
            self.assertEqual(main(list(arguments)), 0)
        return stdout.getvalue()

    def test_manual_task_round_trips_through_prompt_and_outputs(self) -> None:
        self.run_main(
            "manual",
            "--title",
            "Fix the login crash",
            "--description",
            "It crashes on iOS",
            "--output",
            self.task_path,
        )
        self.run_main("prompt", "--task", self.task_path)
        self.run_main("outputs", "--task", self.task_path)
        with open(self.task_path, encoding="utf-8") as handle:
            task = json.load(handle)
        self.assertEqual(task["title"], "Fix the login crash")
        self.assertEqual(task["kind"], "pending")

    def test_select_without_a_key_fails_closed(self) -> None:
        stdout = io.StringIO()
        with redirect_stdout(stdout):
            self.assertEqual(main(["select"]), 1)
        self.assertIn("::error::", stdout.getvalue())

    def test_prompt_rejects_an_empty_task_file(self) -> None:
        with open(self.task_path, "w", encoding="utf-8") as handle:
            handle.write("null")
        stdout = io.StringIO()
        with redirect_stdout(stdout):
            self.assertEqual(
                main(["prompt", "--task", self.task_path]), 1
            )
        self.assertIn("does not contain a task", stdout.getvalue())


if __name__ == "__main__":
    unittest.main()
