"""Fixture tests for tool/parse_review_grade.py.

Run: python3 -m unittest tool.test_parse_review_grade -v
(or: python3 tool/test_parse_review_grade.py)
"""

import json
import unittest

try:
    from parse_review_grade import parse_grade
except ImportError:  # `python -m unittest tool.test_...` from repo root.
    from tool.parse_review_grade import parse_grade


def part(message_id: str, part_type: str, **fields: object) -> str:
    payload = {
        "type": part_type,
        "part": {
            "id": f"prt_{message_id}",
            "messageID": message_id,
            "type": part_type,
            **fields,
        },
    }
    return json.dumps(payload)


REVIEW_BODY = "\n\n## Summary\nLooks fine.\n\n## Findings\n- nit\n"


class ParseReviewGradeTest(unittest.TestCase):
    def test_grade_on_first_line_is_accepted(self) -> None:
        stream = [part("msg_1", "text", text="GRADE: A" + REVIEW_BODY)]

        grade, text = parse_grade(stream)

        self.assertEqual(grade, "A")
        self.assertIn("## Findings", text)

    def test_grade_after_preamble_is_rejected(self) -> None:
        # The grade must be the first line; a later grade line is not trusted.
        stream = [part("msg_1", "text", text="Let me look at the diff.\nGRADE: A" + REVIEW_BODY)]

        grade, _ = parse_grade(stream)

        self.assertEqual(grade, "")

    def test_final_message_wins(self) -> None:
        stream = [
            part("msg_1", "text", text="GRADE: D\n\n## Findings\nfirst draft"),
            part("msg_2", "text", text="GRADE: B" + REVIEW_BODY),
        ]

        grade, text = parse_grade(stream)

        self.assertEqual(grade, "B")
        self.assertNotIn("first draft", text)

    def test_missing_findings_section_is_rejected(self) -> None:
        # A bare grade echoed from the diff must not satisfy the gate.
        stream = [part("msg_1", "text", text="GRADE: A")]

        grade, _ = parse_grade(stream)

        self.assertEqual(grade, "")

    def test_ansi_escape_codes_are_stripped(self) -> None:
        stream = [part("msg_1", "text", text="\u001b[32mGRADE: C\u001b[0m" + REVIEW_BODY)]

        grade, _ = parse_grade(stream)

        self.assertEqual(grade, "C")

    def test_invalid_grade_is_rejected(self) -> None:
        stream = [part("msg_1", "text", text="GRADE: E" + REVIEW_BODY)]

        grade, _ = parse_grade(stream)

        self.assertEqual(grade, "")

    def test_non_json_lines_are_ignored(self) -> None:
        stream = [
            "not json at all",
            part("msg_1", "text", text="GRADE: B" + REVIEW_BODY),
        ]

        grade, _ = parse_grade(stream)

        self.assertEqual(grade, "B")

    def test_empty_stream_yields_no_grade(self) -> None:
        grade, text = parse_grade([])

        self.assertEqual(grade, "")
        self.assertEqual(text, "")


if __name__ == "__main__":
    unittest.main()
