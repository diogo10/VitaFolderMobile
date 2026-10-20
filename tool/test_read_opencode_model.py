"""Fixture tests for tool/read_opencode_model.py.

Run: python3 -m unittest tool.test_read_opencode_model -v
(or: python3 tool/test_read_opencode_model.py)
"""

import os
import unittest

try:
    from read_opencode_model import read_model, strip_jsonc
except ImportError:  # `python -m unittest tool.test_...` from repo root.
    from tool.read_opencode_model import read_model, strip_jsonc


class StripJsoncTest(unittest.TestCase):
    def test_line_comments_are_removed(self) -> None:
        text = '{\n  // a comment\n  "model": "a/b"\n}\n'

        self.assertEqual(strip_jsonc(text).count("//"), 0)
        self.assertIn('"model": "a/b"', strip_jsonc(text))

    def test_block_comments_are_removed(self) -> None:
        text = '{\n  /* block\n     comment */\n  "model": "a/b"\n}\n'

        self.assertNotIn("block", strip_jsonc(text))

    def test_slashes_inside_strings_are_kept(self) -> None:
        text = '{\n  "$schema": "https://opencode.ai/config.json"\n}\n'

        self.assertIn("https://opencode.ai/config.json", strip_jsonc(text))

    def test_trailing_commas_are_removed(self) -> None:
        text = '{\n  "model": "a/b",\n}\n'

        self.assertNotIn(",\n}", strip_jsonc(text))


class ReadModelTest(unittest.TestCase):
    def test_model_is_read(self) -> None:
        self.assertEqual(
            read_model('{\n  // comment\n  "model": "minimax/MiniMax-M3.1-Flash",\n}\n'),
            "minimax/MiniMax-M3.1-Flash",
        )

    def test_missing_model_is_rejected(self) -> None:
        with self.assertRaises(ValueError):
            read_model('{\n  "formatter": true\n}\n')

    def test_env_reference_is_resolved(self) -> None:
        os.environ["OPENCODE_TEST_MODEL"] = "opencode/some-model"
        try:
            self.assertEqual(
                read_model('{\n  "model": "{env:OPENCODE_TEST_MODEL}"\n}\n'),
                "opencode/some-model",
            )
        finally:
            del os.environ["OPENCODE_TEST_MODEL"]

    def test_unset_env_reference_is_rejected(self) -> None:
        os.environ.pop("OPENCODE_TEST_MISSING_MODEL", None)
        with self.assertRaises(ValueError):
            read_model('{\n  "model": "{env:OPENCODE_TEST_MISSING_MODEL}"\n}\n')

    def test_repository_configuration(self) -> None:
        import os.path

        repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        path = os.path.join(repo_root, "opencode.jsonc")
        with open(path, encoding="utf-8") as handle:
            model = read_model(handle.read())

        self.assertIn("/", model)
        self.assertNotIn("{env:", model)


if __name__ == "__main__":
    unittest.main()
