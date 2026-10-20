"""Reads the model from the repository's `opencode.jsonc`.

The CI review workflow uses the same model as the repository configuration so
the bot and local development agree on one model. `opencode.jsonc` is JSONC
(comments, trailing commas), so it is normalised before it is parsed: the
scanner is string-aware, so a `//` inside a string (a URL, for example) is
never mistaken for a comment.

Usage:
  python3 tool/read_opencode_model.py [path/to/opencode.jsonc]

Exit codes:
  0  the model was found and printed to stdout
  1  no usable model was found (the reason is printed to stderr)
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from typing import Any

ENV_PATTERN = re.compile(r"\{env:([A-Za-z_][A-Za-z0-9_]*)\}")


def strip_jsonc(text: str) -> str:
    """Removes comments and trailing commas from a JSONC document."""
    out: list[str] = []
    index = 0
    length = len(text)
    in_string = False

    while index < length:
        char = text[index]

        if in_string:
            out.append(char)
            if char == "\\" and index + 1 < length:
                out.append(text[index + 1])
                index += 2
                continue
            if char == '"':
                in_string = False
            index += 1
            continue

        if char == '"':
            in_string = True
            out.append(char)
            index += 1
            continue

        if char == "/" and index + 1 < length:
            following = text[index + 1]
            if following == "/":
                end = text.find("\n", index)
                if end == -1:
                    break
                out.append("\n")
                index = end + 1
                continue
            if following == "*":
                end = text.find("*/", index + 2)
                if end == -1:
                    break
                out.append("\n" * text.count("\n", index, end))
                index = end + 2
                continue

        if char in "}]":
            # Drop a trailing comma that belongs to this closing bracket.
            for position in range(len(out) - 1, -1, -1):
                if not out[position].isspace():
                    if out[position] == ",":
                        del out[position]
                    break

        out.append(char)
        index += 1

    return "".join(out)


def _resolve_env(value: str) -> str:
    """Replaces {env:NAME} references with the environment values."""
    missing: list[str] = []

    def replace(match: re.Match[str]) -> str:
        name = match.group(1)
        resolved = os.environ.get(name, "")
        if not resolved:
            missing.append(name)
        return resolved

    resolved = ENV_PATTERN.sub(replace, value)
    if missing:
        raise ValueError(
            "model references unset environment variable(s): " + ", ".join(missing)
        )
    return resolved


def read_model(text: str) -> str:
    """Returns the top-level `model` of a JSONC configuration document."""
    document: Any = json.loads(strip_jsonc(text))
    if not isinstance(document, dict):
        raise ValueError("configuration is not a JSON object")
    model = document.get("model")
    if not isinstance(model, str) or not model.strip():
        raise ValueError("no top-level \"model\" entry")
    model = _resolve_env(model.strip())
    if not model:
        raise ValueError("the \"model\" entry resolved to an empty value")
    return model


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "path",
        nargs="?",
        default="opencode.jsonc",
        help="Path to the OpenCode configuration (default: opencode.jsonc).",
    )
    args = parser.parse_args()

    try:
        with open(args.path, encoding="utf-8") as handle:
            text = handle.read()
    except OSError as error:
        print(f"::error::Could not read {args.path}: {error}", file=sys.stderr)
        return 1

    try:
        model = read_model(text)
    except (ValueError, json.JSONDecodeError) as error:
        print(f"::error::Could not read the model from {args.path}: {error}", file=sys.stderr)
        return 1

    print(model)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
