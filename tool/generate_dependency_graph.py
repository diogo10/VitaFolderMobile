"""Generates the feature dependency graph (ADR-0006, Melos workspace).

Run locally: python3 tool/generate_dependency_graph.py [--write]
  --write  rewrites docs/architecture/dependency-graph.md in place.

Scans packages/house_mira_*/lib imports (and legacy lib/features/ when
present) and reports:
  * feature -> feature edges (who imports whom, with import counts),
    split into domain-level (domain/ or application/ importer) vs
    presentation-level edges;
  * layer rule notes (domain/application must only touch other domains,
    never data/presentation/application of another feature).

Counts are import statements, not distinct files: one file with two
cross-feature imports contributes two to the edge count, while the
per-edge file list below each edge header names each importing file
once. Comment handling (full-line `//`, trailing `//`, and `/* ... */`
block comments) is shared with `tool/check_layer_boundaries.py` via
[strip_block_comments] so commented-out imports never produce edges.

Limitation: only imports that name an explicit layer directory are
counted (`package:house_mira/features/<feature>/<layer>/...`). Barrel
imports that stop at the feature root (e.g.
`package:house_mira/features/foo/foo.dart`) carry no layer segment, so
they are skipped and never produce an edge.
"""

import re
import sys
from collections import Counter
from pathlib import Path

try:
    from check_layer_boundaries import strip_block_comments
except ImportError:  # `python tool/generate_dependency_graph.py` from root.
    from tool.check_layer_boundaries import strip_block_comments

ROOT = Path(__file__).resolve().parent.parent
FEATURES = ROOT / 'lib' / 'features'
PACKAGES = ROOT / 'packages'
DOC = ROOT / 'docs' / 'architecture' / 'dependency-graph.md'

# Captures the full import URI in group 1; the feature/layer split is
# derived from it via FEATURE_PATH so single- and double-quoted imports
# (including `as`/`show`/`hide` suffixes) all parse identically.
IMPORT = re.compile(r"""^\s*import\s+['"]([^'"]+)['"]""")
FEATURE_PATH = re.compile(r'package:house_mira/features/([^/]+)/([^/]+)/')
# Melos workspace scheme: package:house_mira_<feature>/<layer>/...
PACKAGE_PATH = re.compile(r'package:house_mira_([a-z_]+)/([^/]+)/')
HEADER_WIDGET = 'package:house_mira/features/people/presentation/widgets/family_header_widget.dart'
HEADER_WIDGET_PKG = (
    'package:house_mira_people/presentation/widgets/family_header_widget.dart'
)
DOMAIN_OR_APP = {'domain', 'application'}

# Maps workspace package suffixes back to short feature names for the graph.
PACKAGE_TO_FEATURE = {
    'people': 'people',
    'reminders': 'reminders',
    'notes': 'notes',
    'home': 'home',
    'account': 'account',
    'login': 'login',
    'onboarding': 'onboarding',
    'paywall': 'paywall',
    'core': 'core',
}


def iter_feature_files():
    """Yields (src_feature, src_layer, rel_display, path) for both layouts."""
    if FEATURES.exists():
        for path in sorted(FEATURES.rglob('*.dart')):
            rel = path.relative_to(FEATURES).parts
            if len(rel) < 3:
                continue
            yield rel[0], rel[1], '/'.join(rel), path
    if PACKAGES.exists():
        for path in sorted(PACKAGES.rglob('*.dart')):
            try:
                rel = path.relative_to(PACKAGES).parts
            except ValueError:
                continue
            # packages/house_mira_<f>/lib/<layer>/...
            if len(rel) < 4 or rel[1] != 'lib':
                continue
            pkg = rel[0]
            if not pkg.startswith('house_mira_'):
                continue
            short = pkg[len('house_mira_') :]
            if short == 'core' or short not in PACKAGE_TO_FEATURE:
                continue
            layer = rel[2]
            if layer.startswith('.'):
                continue
            yield short, layer, f'{short}/{"/".join(rel[2:])}', path


def target_of(uri: str) -> tuple[str, str] | None:
    fm = FEATURE_PATH.search(uri)
    if fm:
        return fm.group(1), fm.group(2)
    pm = PACKAGE_PATH.search(uri)
    if pm:
        short, layer = pm.group(1), pm.group(2)
        if short in PACKAGE_TO_FEATURE and short != 'core':
            return PACKAGE_TO_FEATURE[short], layer
    return None


def scan():
    edges: Counter[tuple[str, str, str]] = Counter()
    per_edge_files: dict[tuple[str, str, str], list[str]] = {}
    header_users: list[str] = []
    for src_feature, src_layer, display, path in iter_feature_files():
        try:
            text = path.read_text()
        except OSError:
            continue
        for line in strip_block_comments(text):
            stripped = line.strip()
            if not stripped or stripped.startswith('//'):
                continue
            m = IMPORT.match(line.split('//', 1)[0])
            if not m:
                continue
            uri = m.group(1)
            target = target_of(uri)
            if target is None:
                continue
            if uri in (HEADER_WIDGET, HEADER_WIDGET_PKG) and (
                src_feature != 'people'
            ):
                header_users.append(display)
            dst_feature, _dst_layer = target
            if dst_feature == src_feature:
                continue
            kind = (
                'domain'
                if src_layer in DOMAIN_OR_APP
                else 'presentation'
            )
            key = (src_feature, dst_feature, kind)
            edges[key] += 1
            per_edge_files.setdefault(key, []).append(display)
    return edges, per_edge_files, sorted(set(header_users))


def render(edges, per_edge_files, header_users) -> str:
    lines = [
        '# Feature dependency graph',
        '',
        '> Generated by `python3 tool/generate_dependency_graph.py --write`.',
        '> Do not hand-edit the edge lists below; fix the imports, re-run,',
        '> and commit the regenerated file.',
        '',
        'Direction: `A --> B` means a file in feature A imports a file',
        'from feature B. `domain` edges originate in `domain/` or',
        '`application/` (business logic); `presentation` edges originate',
        'in `presentation/` or the feature-local `data/` glue.',
        'Edge counts are import statements, not distinct files; each',
        'edge header lists every importing file once.',
        '',
        '```mermaid',
        'flowchart LR',
    ]
    for (src, dst, kind), count in sorted(edges.items()):
        style = '-.->' if kind == 'presentation' else '-->'
        lines.append(f'    {src} {style}|"{kind} x{count} imports"| {dst}')
    lines += ['```', '', '## Edges', '']
    if not edges:
        lines.append('_No cross-feature imports._')
    for (src, dst, kind), count in sorted(edges.items()):
        lines.append(f'### `{src}` → `{dst}` ({kind}, {count} imports)')
        lines.append('')
        for f in sorted(set(per_edge_files[(src, dst, kind)])):
            lines.append(f'- `{f}`')
        lines.append('')
    lines.append('## Target layering (ADR-0006)')
    lines.append('')
    lines += [
        '- `people` is the shared kernel: family/identity entities and',
        '  `PeopleRepository`. Other features depend on its **domain** only.',
        '- `reminders` exposes reminder entities + `ReminderRepository`;',
        '  `home` aggregates both into `HomeEntity` (domain-to-domain).',
        '- No feature imports another feature\'s `data/` (Supabase stays',
        '  behind the repository interface) or another feature\'s',
        '  `presentation/` widgets except the shared `FamilyHeaderWidget`',
        '  (explicit public UI surface, listed below until it moves to',
        '  `core/widgets/` in Phase 2).',
        '- Presentation cross-imports of `FamilyHeaderWidget`:',
    ]
    for f in header_users:
        lines.append(f'  - `{f}`')
    lines.append('')
    # lines ends with a '' sentinel, so join already yields one trailing
    # newline; normalize to exactly one (no double-newline).
    return '\n'.join(lines).rstrip('\n') + '\n'


def main() -> None:
    edges, per_edge_files, header_users = scan()
    doc = render(edges, per_edge_files, header_users)
    if '--write' in sys.argv:
        DOC.parent.mkdir(parents=True, exist_ok=True)
        DOC.write_text(doc)
        print(f'Wrote {DOC.relative_to(ROOT)}')
    else:
        print(doc)


if __name__ == '__main__':
    main()
