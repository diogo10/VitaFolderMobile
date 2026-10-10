"""Enforces feature/layer dependency rules (ADR-0006).

Run locally: python3 tool/check_layer_boundaries.py
CI runs the same script (see .github/workflows/ci.yml) and fails the PR
on any violation. Rules:

R1 DOMAIN PURITY .... no `package:flutter*` or `dart:ui` import in
   lib/**/domain/ (Flutter engine types stay in presentation/).
R2 SUPABASE BOUNDARY  `supabase` imports only in lib/features/*/data/,
   lib/core/{auth,functions}/, and the two composition roots
   (lib/main.dart session init, lib/core/injections/service_locator.dart
   AuthService wiring).
R3 DI BOUNDARY ....... no `get_it` / service-locator imports anywhere
   under lib/features/ (resolution lives in lib/core/injections/,
   the router, and main.dart; widgets take constructor injection).
R4 DOMAIN ISOLATION .. a file under lib/features/<a>/domain/ or
   .../application/ must not import another feature's data/,
   application/, or presentation/ (domain-to-domain and
   application-to-domain sharing is allowed and graphed; same-feature
   domain->data imports are grandfathered tech debt, see ADR-0006).
   Both `import` and `export` directives are scanned, and relative
   imports that resolve outside the owning feature (e.g.
   `../../../people/domain/x.dart`) are treated like their equivalent
   `package:` import. Comment handling: full-line `//` comments are
   skipped, trailing `//` comments are stripped before the R3
   locate-call scan, and `/* ... */` block comments (single-line and
   multi-line) are stripped before all checks (see [strip_block_comments],
   shared with `tool/generate_dependency_graph.py`).
R5 ONE STATE MGMT .... no `package:provider` imports under lib/features/
   (flutter_bloc only; the single root Provider in main.dart is
   grandfathered until migration Phase 1 removes it).
"""

import posixpath
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / 'lib'
FEATURES = LIB / 'features'

# Matches both `import` and `export` directives; group 1 is the URI.
# Single- and double-quoted URIs (including `as`/`show`/`hide` suffixes)
# all parse identically because only the quoted URI is captured.
DIRECTIVE = re.compile(r"""^\s*(?:import|export)\s+['"]([^'"]+)['"]""")
# Legacy alias kept for readability at call sites that only care about
# imports; identical to DIRECTIVE.
IMPORT = DIRECTIVE
# Direct service-location calls (checked outside comments).
# Matches GetIt.instance, GetIt.I (shorthand), and slInstance<...>().
LOCATE_CALL = re.compile(r'GetIt\s*\.\s*instance|GetIt\s*\.\s*I\b|slInstance\s*[<(]')

CORE_SUPABASE_ALLOW = ('lib/core/auth/', 'lib/core/functions/')
# Composition roots: session init (main) and AuthService wiring
# (service locator) necessarily touch the Supabase singleton.
ROOT_SUPABASE_ALLOW = (
    'lib/main.dart',
    'lib/core/injections/service_locator.dart',
)

failures: list[str] = []


def fail(rule: str, path: str, detail: str) -> None:
    failures.append(f'{rule} {path}: {detail}')


def strip_block_comments(text: str) -> list[str]:
    """Removes `/* ... */` spans, preserving one entry per input line.

    Tracks spans across lines so multi-line block comments hide every line
    until the closing `*/`; inline block comments leave the surrounding
    code intact. Shared with `tool/generate_dependency_graph.py` so both
    tools agree on what is code and what is comment.
    """
    lines: list[str] = []
    in_block = False
    for raw in text.splitlines():
        line = raw
        # Strip /* ... */ block comments, tracking spans across lines.
        while True:
            if in_block:
                end = line.find('*/')
                if end == -1:
                    line = ''
                    break
                line = line[end + 2 :]
                in_block = False
            else:
                start = line.find('/*')
                if start == -1:
                    break
                end = line.find('*/', start + 2)
                if end == -1:
                    line = line[:start]
                    in_block = True
                    break
                line = line[:start] + line[end + 2 :]
        lines.append(line)
    return lines


def resolve_relative_uri(rel: str, uri: str) -> str | None:
    """Resolves a relative directive URI against the importing file.

    `rel` is the repo-rooted posix path of the importing file (e.g.
    `lib/features/home/domain/u.dart`); returns the normalized
    repo-rooted posix path of the target, or None when the URI is not a
    relative path or escapes the repo root.
    """
    if uri.startswith('package:') or uri.startswith('dart:'):
        return None
    if uri.startswith('/') or '://' in uri:
        return None
    base = posixpath.dirname(rel)
    target = posixpath.normpath(posixpath.join(base, uri))
    if target == '.' or target.startswith('..'):
        return None
    return target


def r4_target_feature_layer(target: str, feature: str) -> str | None:
    """Returns the offending layer when `target` violates R4, else None.

    `target` is a normalized feature-relative check: either the captured
    `package:house_mira/features/<other>/<layer>/...` groups or a resolved
    relative path under `lib/features/<other>/<layer>/...`.
    """
    m = re.match(r'package:house_mira/features/([^/]+)/([^/]+)/', target)
    if m:
        other, layer = m.group(1), m.group(2)
    else:
        parts = target.split('/')
        if len(parts) < 4 or parts[0] != 'lib' or parts[1] != 'features':
            return None
        other, layer = parts[2], parts[3]
    if other != feature and layer in ('data', 'application', 'presentation'):
        return layer
    return None


def iter_lib_dart():
    return sorted(LIB.rglob('*.dart'))


def feature_of(path: Path) -> str | None:
    try:
        rel = path.relative_to(FEATURES).parts
    except ValueError:
        return None
    return rel[0] if len(rel) > 1 else None


def check_text(
    rel: str,
    feature: str | None,
    layer: str | None,
    text: str,
) -> list[str]:
    """Returns violation strings for one file's text (testable helper).

    Scans both `import` and `export` directives; relative URIs that
    resolve outside the owning feature are checked exactly like their
    equivalent `package:` import. Comment handling: full-line `//`
    comments are skipped, trailing `//` comments are stripped before
    the R3 locate-call scan, and `/* ... */` block comments (single-line
    and multi-line) are stripped before all checks.
    """
    hits: list[str] = []
    for line in strip_block_comments(text):
        stripped = line.strip()
        if not stripped or stripped.startswith('//'):
            continue
        # Ignore trailing // comments for locate-call detection so a
        # commented-out call never flags real code.
        code = line.split('//', 1)[0]
        if feature is not None and LOCATE_CALL.search(code):
            hits.append(f'R3 {rel}: direct service location: {stripped[:80]}')
        match = DIRECTIVE.match(line)
        if not match:
            continue
        uri = match.group(1)

        # R1: domain has zero Flutter imports (package:flutter* or
        # dart:ui engine types).
        if layer == 'domain' and (
            uri.startswith('package:flutter') or uri.startswith('dart:ui')
        ):
            hits.append(f'R1 {rel}: Flutter import in domain: {uri}')

        # R2: Supabase stays at the data boundary.
        if 'supabase' in uri:
            allowed = (
                layer == 'data'
                or rel.startswith(CORE_SUPABASE_ALLOW)
                or rel in ROOT_SUPABASE_ALLOW
            )
            if not allowed:
                hits.append(f'R2 {rel}: Supabase import outside data: {uri}')

        # R3: no GetIt/service-locator imports inside features.
        if feature is not None and (
            uri.startswith('package:get_it')
            or uri.endswith('/service_locator.dart')
            or 'core/injections/service_locator' in uri
        ):
            hits.append(f'R3 {rel}: DI import inside feature: {uri}')

        # R4: domain and application must not reach into another
        # feature's data/application/presentation layers.
        if layer in ('domain', 'application'):
            offending = r4_target_feature_layer(uri, feature or '')
            if offending is None and feature is not None:
                resolved = resolve_relative_uri(rel, uri)
                if resolved is not None:
                    offending = r4_target_feature_layer(resolved, feature)
            if offending is not None:
                hits.append(f'R4 {rel}: domain reaches into {uri}')

        # R5: flutter_bloc only under features.
        if feature is not None and uri.startswith('package:provider/'):
            hits.append(f'R5 {rel}: provider import in feature: {uri}')
    return hits


def layer_of(path: Path) -> str | None:
    try:
        rel = path.relative_to(FEATURES).parts
    except ValueError:
        return None
    if len(rel) > 2 and rel[1] in (
        'domain',
        'data',
        'application',
        'presentation',
    ):
        return rel[1]
    return None


def main() -> None:
    failures.clear()
    files = iter_lib_dart()
    if not files:
        print('::error::No Dart files found under lib/.')
        sys.exit(1)

    for path in files:
        rel = path.relative_to(ROOT).as_posix()
        feature = feature_of(path)
        layer = layer_of(path)
        try:
            text = path.read_text()
        except OSError as exc:
            fail('IO', rel, str(exc))
            continue
        failures.extend(check_text(rel, feature, layer, text))

    if failures:
        print('::error::Layer-boundary violations (ADR-0006):')
        for item in failures:
            print(f'::error:: - {item}')
        sys.exit(1)

    print(f'Layer boundaries hold ({len(files)} lib files checked).')


if __name__ == '__main__':
    main()
