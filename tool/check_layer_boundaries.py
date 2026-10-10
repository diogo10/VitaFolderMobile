"""Enforces feature/layer dependency rules (ADR-0006).

Run locally: python3 tool/check_layer_boundaries.py
CI runs the same script (see .github/workflows/ci.yml) and fails the PR
on any violation. Rules:

R1 DOMAIN PURITY .... no `package:flutter*` import in lib/**/domain/.
R2 SUPABASE BOUNDARY  `supabase` imports only in lib/features/*/data/,
   lib/core/{auth,functions}/, and the two composition roots
   (lib/main.dart session init, lib/core/injections/service_locator.dart
   AuthService wiring).
R3 DI BOUNDARY ....... no `get_it` / service-locator imports anywhere
   under lib/features/ (resolution lives in lib/core/injections/,
   the router, and main.dart; widgets take constructor injection).
R4 DOMAIN ISOLATION .. a file under lib/features/<a>/domain/ must not
   import another feature's data/, application/, or presentation/
   (domain-to-domain sharing is allowed and graphed).
R5 ONE STATE MGMT .... no `package:provider` imports under lib/features/
   (flutter_bloc only; the single root Provider in main.dart is
   grandfathered until migration Phase 1 removes it).
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / 'lib'
FEATURES = LIB / 'features'

IMPORT = re.compile(r"""^\s*import\s+['"]([^'"]+)['"]""")
# Direct service-location calls (checked outside comments).
LOCATE_CALL = re.compile(r'GetIt\s*\.\s*instance|slInstance\s*[<(]')

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
    """Returns violation strings for one file's text (testable helper)."""
    hits: list[str] = []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith('//'):
            continue
        if feature is not None and LOCATE_CALL.search(line):
            hits.append(f'R3 {rel}: direct service location: {stripped[:80]}')
        match = IMPORT.match(line)
        if not match:
            continue
        uri = match.group(1)

        # R1: domain has zero Flutter imports.
        if layer == 'domain' and uri.startswith('package:flutter'):
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

        # R4: domain must not reach into another feature's
        # data/application/presentation layers.
        if layer == 'domain':
            m = re.match(
                r'package:house_mira/features/([^/]+)/([^/]+)/', uri,
            )
            if m and m.group(1) != feature and m.group(2) in (
                'data',
                'application',
                'presentation',
            ):
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
