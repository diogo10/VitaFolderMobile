"""Extracts the review grade from an OpenCode v2 run stream.

The CI review workflow runs `opencode run --format json`, which emits one
JSON object per line (JSONL). Every line carries a `part`; text parts hold
the model's output. This script picks the *final* assistant message, requires
its header to carry the grade line `GRADE: <A|B|C|D>`, and prints the letter.

The gate is deliberately strict and fails closed: a run whose output does not
carry a grade line yields no grade, so the workflow can never mistake a
malformed or injected review for an approval. The final message must also
contain the `## Findings` section the review prompt mandates, so a bare
`GRADE: A` echoed from the diff cannot satisfy the gate on its own.

The grade may sit behind a short preamble: models routinely answer with a
status line first ("Grading your PR - checking ..."). The gate therefore
accepts the grade in the first few non-empty lines, but only when the message
carries exactly one grade line and the grade is still in the header, before
any markdown heading. Anything else - no grade, several grades, or a grade
buried in the body - is rejected.

Usage:
  opencode run --format json ... | python3 tool/parse_review_grade.py \
      --text-out /tmp/review_comment.txt

Exit codes:
  0  a valid grade was found (the letter is printed to stdout)
  1  no valid grade was found (the reason is printed to stderr)
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from typing import Any

GRADE_PATTERN = re.compile(r"^GRADE: ([ABCD])$")
FINDINGS_PATTERN = re.compile(r"^\s{0,3}#{1,6}\s*findings\b", re.IGNORECASE | re.MULTILINE)
HEADING_PATTERN = re.compile(r"^\s{0,3}#{1,6}\s")
ANSI_PATTERN = re.compile(r"\x1b\[[0-9;?]*[ -/]*[@-~]")

# How many non-empty lines may precede the grade line. The models answer
# with at most a two-line status line before the grade.
HEADER_LINES = 3


def _strip_ansi(text: str) -> str:
    """Removes ANSI escape sequences from model output."""
    return ANSI_PATTERN.sub("", text)


def _collect_text_parts(stream: Any) -> list[tuple[str, str]]:
    """Returns (message_id, text) for every text part, in stream order."""
    parts: list[tuple[str, str]] = []
    for line in stream:
        line = line.strip()
        if not line:
            continue
        try:
            payload = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(payload, dict):
            continue
        part = payload.get("part", payload)
        if not isinstance(part, dict):
            continue
        if part.get("type") != "text":
            continue
        text = part.get("text")
        if not isinstance(text, str) or not text.strip():
            continue
        parts.append((str(part.get("messageID", "")), _strip_ansi(text)))
    return parts


def _final_message_text(parts: list[tuple[str, str]]) -> str:
    """Concatenates the text parts of the last message that produced output."""
    if not parts:
        return ""
    last_message_id = parts[-1][0]
    return "\n".join(text for message_id, text in parts if message_id == last_message_id)


def _find_grade(text: str) -> str:
    """Returns the grade from the header of the review, or "" when invalid.

    The grade must be the only grade line of the message and it must sit in
    the header: within the first `HEADER_LINES` non-empty lines and before
    any markdown heading. A grade buried in the review body is not trusted.
    """
    lines = text.splitlines()
    grades = [
        (index, match.group(1))
        for index, line in enumerate(lines)
        if (match := GRADE_PATTERN.match(line.strip())) is not None
    ]
    if len(grades) != 1:
        # No grade at all, or an ambiguous message with several grades.
        return ""
    index, grade = grades[0]
    preceding = lines[:index]
    if sum(1 for line in preceding if line.strip()) >= HEADER_LINES:
        # Too much text before the grade: the grade is not in the header.
        return ""
    if any(HEADING_PATTERN.match(line) for line in preceding):
        # The grade comes after a section heading, so it is part of the body.
        return ""
    return grade


def parse_grade(stream: Any) -> tuple[str, str]:
    """Returns (grade, final_message_text); grade is empty when invalid."""
    text = _final_message_text(_collect_text_parts(stream))
    if not text.strip():
        return "", text
    grade = _find_grade(text)
    if not grade:
        return "", text
    if FINDINGS_PATTERN.search(text) is None:
        # The review prompt mandates a "## Findings" section; without it the
        # output is not a complete review, so it never counts as approval.
        return "", text
    return grade, text


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--text-out",
        help="Writes the final assistant message to this file.",
    )
    args = parser.parse_args()

    grade, text = parse_grade(sys.stdin)

    if args.text_out:
        with open(args.text_out, "w", encoding="utf-8") as handle:
            handle.write(text)

    if not grade:
        print(
            "::error::No 'GRADE: <A|B|C|D>' line found at the start of the "
            "review output; treating the review as not merge-ready.",
            file=sys.stderr,
        )
        return 1

    print(grade)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
