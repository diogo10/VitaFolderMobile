"""Enforces 100% line coverage per file under lib/**/domain/,
lib/**/application/, packages/*/lib/**/domain/, or
packages/*/lib/**/application/ (Melos workspace).

Reads coverage/lcov.info (written by `flutter test --coverage`) and fails
when any business-logic file drops below 100%. Extracted from the inline
CI script so it can also run locally: `python3 tool/check_business_logic_coverage.py`.

Melos workspace: aggregates the root `coverage/lcov.info` plus every
`packages/*/coverage/lcov.info` (each package resolves its own `lib/`
paths, so entries are namespaced per package before merging).
"""
import glob
import sys

LCOV_ROOT = 'coverage/lcov.info'
LCOV_PACKAGES = 'packages/*/coverage/lcov.info'


def parse_lcov(path, namespace):
    files = {}
    current = None
    try:
        with open(path) as f:
            for raw in f:
                line = raw.strip()
                if line.startswith('SF:'):
                    current = f'{namespace}:{line[3:]}'
                    files.setdefault(current, [0, 0])
                elif line.startswith('DA:') and current is not None:
                    parts = line[3:].split(',')
                    if len(parts) >= 2:
                        files[current][1] += 1
                        try:
                            if int(parts[1]) > 0:
                                files[current][0] += 1
                        except ValueError:
                            pass
                elif line == 'end_of_record':
                    current = None
    except FileNotFoundError:
        print(f'::warning::Coverage file not found (skipped): {path}')
    return files


def lcov_candidates():
    found = []
    try:
        with open(LCOV_ROOT):
            found.append((LCOV_ROOT, 'app'))
    except FileNotFoundError:
        pass
    for path in sorted(glob.glob(LCOV_PACKAGES)):
        namespace = path.split('/')[1]
        found.append((path, namespace))
    return found


def is_business_logic(path):
    # Layer convention: application/ holds use cases/services,
    # domain/ holds entities/repositories/usecases.
    return '/domain/' in path or '/application/' in path


def main():
    candidates = lcov_candidates()
    if not candidates:
        print('::error::No coverage files found (root or packages).')
        sys.exit(1)
    files: dict[str, list[int]] = {}
    for path, namespace in candidates:
        for key, value in parse_lcov(path, namespace).items():
            files.setdefault(key, [0, 0])
            files[key][0] += value[0]
            files[key][1] += value[1]
    business = {k: v for k, v in files.items() if is_business_logic(k)}

    if not business:
        print('::error::No business-logic files found in coverage.')
        sys.exit(1)

    failures = []
    total_hit = 0
    total_found = 0
    for path in sorted(business):
        hit, found = business[path]
        total_hit += hit
        total_found += found
        pct = 100.0 * hit / found if found else 100.0
        print(f'{pct:6.2f}% ({hit}/{found}) {path}')
        if pct < 100.0:
            failures.append(path)

    total_pct = 100.0 * total_hit / total_found if total_found else 100.0
    print(f'TOTAL business logic: {total_pct:.2f}% ({total_hit}/{total_found})')

    if failures:
        print('::error::Business-logic coverage below 100% for:')
        for path in failures:
            print(f'::error:: - {path}')
        sys.exit(1)

    print('Business-logic coverage is 100%.')


if __name__ == '__main__':
    main()
