#!/usr/bin/env python3
"""Resolve the production release version (pubspec.yaml `1.0.0+1` format).

Used ONLY by the production AAB release workflow
(.github/workflows/build_aab_release.yml) so versioning/build-number logic
never affects development or profile builds.

Resolution rules:
  1. Read `version: <name>+<number>` from pubspec.yaml.
  2. An explicit `--version-name` / `--build-number` override wins, but must
     still pass validation.
  3. Anything malformed is a hard error (exit non-zero) -- never fall back
     to a guessed default.

Validation:
  * version name: exactly `MAJOR.MINOR.PATCH` (digits only).
  * build number: positive integer (Android versionCode requirement).

Output: prints `VERSION_NAME=<...>` and `BUILD_NUMBER=<...>` lines, and when
`GITHUB_OUTPUT` is set, appends `version_name=` / `build_number=` there too.

Usage:
  python3 tool/resolve_release_version.py [--pubspec PATH]
      [--version-name X.Y.Z] [--build-number N]
"""

from __future__ import annotations

import argparse
import os
import re
import sys

VERSION_LINE_RE = re.compile(r"^version\s*:\s*(.+?)\s*(?:#.*)?$")
VERSION_NAME_RE = re.compile(r"^\d+\.\d+\.\d+$")
BUILD_NUMBER_RE = re.compile(r"^[1-9]\d*$")


def parse_pubspec_version(pubspec_path: str) -> tuple[str, str]:
    """Return (version_name, build_number) from a pubspec.yaml file.

    Raises ValueError when the file is missing the version or it is
    malformed -- callers must fail loudly instead of guessing.
    """
    try:
        with open(pubspec_path, encoding="utf-8") as handle:
            lines = handle.read().splitlines()
    except OSError as exc:
        raise ValueError(f"cannot read pubspec file: {pubspec_path}: {exc}") from exc

    raw: str | None = None
    for line in lines:
        match = VERSION_LINE_RE.match(line.strip())
        if match:
            raw = match.group(1).strip().strip("'\"")
            break

    if raw is None:
        raise ValueError(f"no `version:` entry found in {pubspec_path}")

    if "+" in raw:
        name, number = raw.split("+", 1)
    else:
        raise ValueError(
            f"malformed version {raw!r} in {pubspec_path}: "
            "expected `<name>+<number>` (e.g. `1.0.0+1`)",
        )

    validate_version_name(name.strip())
    validate_build_number(number.strip())
    return name.strip(), number.strip()


def validate_version_name(value: str) -> str:
    if not VERSION_NAME_RE.match(value):
        raise ValueError(
            f"invalid version name {value!r}: expected MAJOR.MINOR.PATCH "
            "(e.g. `1.0.0`)",
        )
    return value


def validate_build_number(value: str) -> str:
    if not BUILD_NUMBER_RE.match(value):
        raise ValueError(
            f"invalid build number {value!r}: expected a positive integer "
            "(Android versionCode, e.g. `1`)",
        )
    return value


def resolve(
    pubspec: str,
    version_name_override: str | None,
    build_number_override: str | None,
) -> tuple[str, str]:
    pub_name, pub_number = parse_pubspec_version(pubspec)

    name = pub_name
    if version_name_override is not None and version_name_override != "":
        name = validate_version_name(version_name_override.strip())

    number = pub_number
    if build_number_override is not None and build_number_override != "":
        number = validate_build_number(build_number_override.strip())

    return name, number


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Resolve production release version from pubspec.yaml.",
    )
    parser.add_argument("--pubspec", default="pubspec.yaml")
    parser.add_argument("--version-name", default=None)
    parser.add_argument("--build-number", default=None)
    args = parser.parse_args(argv)

    try:
        name, number = resolve(
            args.pubspec,
            args.version_name,
            args.build_number,
        )
    except ValueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    print(f"VERSION_NAME={name}")
    print(f"BUILD_NUMBER={number}")

    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a", encoding="utf-8") as handle:
            handle.write(f"version_name={name}\n")
            handle.write(f"build_number={number}\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
