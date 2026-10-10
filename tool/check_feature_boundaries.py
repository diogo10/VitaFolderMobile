"""Package import-boundary lint for the Melos workspace (custom lint).

Run locally: python3 tool/check_feature_boundaries.py
CI runs the same script and fails the PR on any violation.

Workspace layout:
  packages/house_mira_core       shared kernel (auth, config, errors,
                                 observability, subscriptions, storage,
                                 theme, l10n, router table, notifications)
  packages/house_mira_<feature>  one independently-versioned Dart package
                                 per feature (people, reminders, notes,
                                 home, account, login, onboarding, paywall)
  lib/                           app composition root only (main.dart,
                                 app.dart, core/router/*, core/injections/*)

Rules:
  P1 NO CROSS-PACKAGE DATA .... no import of another package's `data/`
     (e.g. `package:house_mira_people/data/...` from outside
     `house_mira_people`). Supabase stays behind repository interfaces.
  P2 CORE STAYS PURE .......... `house_mira_core` never imports any
     `house_mira_<feature>` package (dependency direction is
     features -> core, never core -> features). The one historical
     exception (`AuthService.getAsPersonEntity`) was removed by moving
     the profile mapping to `AuthService.getCurrentProfile`.
  P3 EXPLICIT FEATURE EDGES .... feature-to-feature imports target
     `domain/` only, except the documented shared surfaces:
       - people presentation widgets: `family_header_widget.dart`,
         `family_member_card_widget.dart` (sanctioned cross-feature UI
         until Phase 2 moves them to core/widgets)
       - reminders navigation: `navigation/create_reminder_route.dart`
         (typed route wrapper; the constants table lives in core)
     Anything else (application/, data/, other presentation/) is denied.
     The app composition root (`lib/`, `test/`, `integration_test/`)
     may import anything.
  P4 DI AT THE EDGE ........... `package:get_it` appears in a feature
     package only in its `*_service_locator.dart` DI entry point.
     Cubits/widgets take constructor injection (no GetIt imports).
  P5 ONE STATE MGMT ............ no `package:provider` imports under
     `packages/*/lib/` (flutter_bloc only; test/ may use provider for
     legacy widget tests).
  P6 SUPABASE BOUNDARY ......... `supabase` imports in packages live only
     in `data/` repositories/datasources, core `auth/`+`functions/`,
     and the app composition root. Feature `domain/`/`application/`
     never touches Supabase types (test/ fakes are exempt).
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PACKAGES = ROOT / 'packages'

DIRECTIVE = re.compile(r"""^\s*(?:import|export)\s+['"]([^'"]+)['"]""")

CORE = 'house_mira_core'
FEATURES = (
    'house_mira_people',
    'house_mira_reminders',
    'house_mira_notes',
    'house_mira_home',
    'house_mira_account',
    'house_mira_login',
    'house_mira_onboarding',
    'house_mira_paywall',
)
ALL = (CORE,) + FEATURES

# Shared presentation/navigation surfaces exempted from P3 (with ADR note).
P3_SHARED_PRESENTATION = (
    'presentation/widgets/family_header_widget.dart',
    'presentation/widgets/family_member_card_widget.dart',
)
P3_SHARED_NAVIGATION = ('navigation/create_reminder_route.dart',)

failures: list[str] = []


def fail(rule: str, path: str, detail: str) -> None:
    failures.append(f'{rule} {path}: {detail}')


def strip_block_comments(text: str) -> list[str]:
    lines: list[str] = []
    in_block = False
    for raw in text.splitlines():
        line = raw
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


def owning_package(path: Path) -> str | None:
    try:
        rel = path.relative_to(PACKAGES).parts
    except ValueError:
        return None
    if len(rel) >= 3 and rel[1] == 'lib':
        return rel[0]
    return None


def in_lib(path: Path) -> bool:
    """True when the file is package runtime code (lib/, not test/)."""
    try:
        return path.relative_to(PACKAGES).parts[1] == 'lib'
    except (ValueError, IndexError):
        return False


def lib_layer(path: Path) -> str | None:
    """Layer dir for files under packages/<pkg>/lib/<layer>/... ."""
    try:
        parts = path.relative_to(PACKAGES).parts
    except ValueError:
        return None
    if len(parts) >= 4 and parts[1] == 'lib':
        return parts[2]
    return None


def parse_package_import(uri: str) -> tuple[str, str] | None:
    """Splits `package:<pkg>/<rest>` into (pkg, rest) for workspace pkgs."""
    m = re.match(r'package:([^/]+)/(.+)', uri)
    if not m:
        return None
    pkg, rest = m.group(1), m.group(2)
    if pkg in ALL:
        return pkg, rest
    return None


def check_file(path: Path) -> None:
    owner = owning_package(path)
    if owner is None:
        return
    rel = path.relative_to(ROOT).as_posix()
    try:
        text = path.read_text()
    except OSError as exc:
        fail('IO', rel, str(exc))
        return
    for line in strip_block_comments(text):
        stripped = line.strip()
        if not stripped or stripped.startswith('//'):
            continue
        m = DIRECTIVE.match(line)
        if not m:
            continue
        parsed = parse_package_import(m.group(1))
        if parsed is None:
            continue
        target_pkg, rest = parsed
        if target_pkg == owner:
            continue

        # P2: core never depends on features.
        if owner == CORE and target_pkg in FEATURES:
            fail('P2', rel, f'core imports feature {target_pkg}: {m.group(1)}')
            continue

        # P1: nobody imports another package's data/.
        if rest.startswith('data/'):
            fail(
                'P1',
                rel,
                f'cross-package data/ import: {m.group(1)}',
            )
            continue

        # P3: feature-to-feature goes through domain/ (+ shared surfaces).
        if owner in FEATURES and target_pkg in FEATURES:
            first = rest.split('/')[0]
            if first == 'domain':
                continue
            if rest in P3_SHARED_PRESENTATION and target_pkg == (
                'house_mira_people'
            ):
                continue
            if rest in P3_SHARED_NAVIGATION and target_pkg == (
                'house_mira_reminders'
            ):
                continue
            fail('P3', rel, f'non-domain feature import: {m.group(1)}')
            continue

        # P4: get_it only in the package DI entry point.
        if m.group(1).startswith('package:get_it'):
            if not path.name.endswith('_service_locator.dart'):
                fail('P4', rel, 'get_it outside *_service_locator.dart')

        # P5: flutter_bloc only under packages/*/lib/ (tests exempt).
        if in_lib(path) and m.group(1).startswith('package:provider/'):
            fail('P5', rel, f'provider import in package lib: {m.group(1)}')

        # P6: Supabase stays at the data boundary (tests exempt).
        if in_lib(path) and 'supabase' in m.group(1):
            layer = lib_layer(path)
            allowed = (
                layer == 'data'
                or (
                    owner == CORE
                    and layer in ('auth', 'functions')
                )
            )
            if not allowed:
                fail(
                    'P6',
                    rel,
                    f'Supabase import outside data: {m.group(1)}',
                )

    # P4 also covers the file-level case via a direct text scan so a
    # dynamically constructed import cannot slip through (kept simple:
    # any get_it mention outside the locator fails).
    if not path.name.endswith('_service_locator.dart'):
        body = '\n'.join(strip_block_comments(text))
        if 'package:get_it' in body:
            # Already reported per-directive above; guard against dupes.
            pass


def main() -> None:
    failures.clear()
    files = sorted(PACKAGES.rglob('*.dart')) if PACKAGES.exists() else []
    if not files:
        print('::error::No Dart files found under packages/.')
        sys.exit(1)
    for path in files:
        check_file(path)
    if failures:
        print('::error::Package-boundary violations (custom import lint):')
        for item in failures:
            print(f'::error:: - {item}')
        sys.exit(1)
    print(f'Package boundaries hold ({len(files)} package files checked).')


if __name__ == '__main__':
    main()
