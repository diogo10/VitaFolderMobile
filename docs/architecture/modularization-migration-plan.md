# Modularization migration plan: single package → Dart packages per feature

Companion to ADR-0006 (decision) and `dependency-graph.md` (current
edges, generated). Goal: one Dart package per feature with an explicit
public API, without ever breaking CI (`flutter analyze` clean, 100%
per-file `domain/`+`application/` coverage).

> Workspace status (this PR): the Melos workspace is live — `packages/`
> holds `house_mira_core` + 8 feature packages (independently versioned,
> `CODEOWNERS`-owned), the app shell keeps only the composition root
> (`main.dart`, `core/router/*`, `core/injections/service_locator.dart`),
> and `tool/check_feature_boundaries.py` (P1–P4) enforces the import
> rules in CI alongside R1–R5. Decoupling landed with it: the route
> table lives in core (typed reminder routes in the reminders package),
> `AuthService` exposes core-pure `getCurrentProfile()` (no
> core→people import), and account settings depend on core's
> `NotificationSender` (no account→reminders application import).
> Remaining Phase 2 item: move the two shared people widgets to
> `core/widgets/` and switch repository contracts to entities.

## Current state (2026-10-10, measured)

- 186 Dart files in `lib/`, ~29k LOC. Features: people (33 files),
  reminders (30), notes (21), account/home (17 each), paywall (13),
  onboarding (8), login (3). Core: 34 files.
- `people` domain is the shared kernel (10 cross-feature edge groups all
  point at `people` and/or `reminders` domains; `home` aggregates both).
- Boundary debts just paid (this PR): zero Flutter imports in `domain/`
  (`package:meta` for `@immutable`, palettes moved to presentation), zero
  GetIt in widgets/pages (constructor injection + router `*Factory`
  seams), zero `package:provider` in features, R1–R5 enforced in CI.
- Remaining grandfathered items: root `Provider<AuthService>` in
  `main.dart` (R5 exempts it) and cross-feature `FamilyHeaderWidget` reuse
  (3 importers — the only sanctioned presentation-level sharing).

## Package shape (target)

```
packages/
  people/            # kernel: entities, PeopleRepository, usecases
    lib/
      people.dart            # barrel: domain API ONLY
      src/domain/...
      src/data/...           # impl, supabase inside
      src/presentation/...   # NOT exported (except documented widgets)
  reminders/  notes/  paywall/  onboarding/  login/  home/  account/
  core_*/ ...                # later: split lib/core/ (auth, subscriptions…)
```

- Each package: `src/` layout, barrel export = public API (domain
  entities, repository interfaces, use cases). Data + presentation are
  `src/`-private; any cross-package widget sharing is an explicit export
  with an ADR note, default deny.
- Dependency rules (same as R1–R5, now as pubspec boundaries):
  domain packages are pure Dart (`meta`, `fpdart` only — no `flutter`,
  no `supabase`); `data` depends on `domain` + `supabase_flutter`;
  `presentation` depends on `flutter_bloc`, never `provider`.
- DI stays GetIt-at-the-root (ADR-0002): the app package wires per-feature
  graphs; feature packages expose `register*()` functions instead of
  `core/injections/*_service_locator.dart`. Router `*Factory` seams are
  unchanged — they just resolve from packages.

## Phases (each phase = own PR, CI green throughout)

### Phase 0 — Gate portability (precondition, ~0.5 day)

- Extend `tool/check_business_logic_coverage.py` path filter from
  `lib/**/domain|application` to also match `packages/*/lib/src/
  domain|application` (or wherever the package keeps business logic).
  Land and verify against the current tree (no behavior change).
- Acceptance: coverage script passes unchanged on `lib/`; supports
  `packages/` paths (unit-tested with a fixture lcov).

### Phase 1 — Root provider removal (~0.5 day)

- Replace root `Provider<AuthService>` in `main.dart` with the
  `flutter_bloc` equivalent scope; delete the R5 grandfather clause and
  the `provider` dependency if nothing else uses it.
- Acceptance: R5 covers 100% of `lib/`; `grep provider lib/` clean.

### Phase 2 — Shared UI extraction (~1 day)

- Move `FamilyHeaderWidget` (+ `FamilyMemberCardWidget` if the graph
  shows reuse) to `lib/core/widgets/` (or a `design` package later);
  update the 3 cross-feature importers.
- Follow-up (same phase): remove the grandfathered same-feature
  `domain/` → `data/` imports (notes/reminders repository contracts and
  use cases referencing `NoteModel`/`ReminderModel`; R4 intentionally
  scopes to cross-feature edges until then). Switch the contracts to
  entities (`NoteEntity`/`ReminderEntity`) with mappers at the
  `data/` boundary.
- Acceptance: graph shows zero presentation→presentation cross-feature
  edges; R4 extended to forbid them (remove the documented exception).

### Phase 3 — Leaf packages first (~1–2 days each, parallelizable)

Order: `login` → `onboarding` → `paywall` (no incoming domain edges;
smallest). For each:

1. Create `packages/<feature>/` with `src/domain|data|presentation`,
   move files + their tests, barrel-export domain API only.
2. Point the app at the package (`path:` dependency), delete the
   `lib/features/<feature>/` tree, update router/locator imports.
3. Regenerate `dependency-graph.md` (extend the generator to scan
   `packages/`), run analyze + full tests + coverage gate.

- Acceptance per package: analyze clean, coverage 100% on moved files,
  graph edges unchanged in kind (only the path prefix changes).

### Phase 4 — Kernel package (~2–3 days)

- Extract `people` (most imported: every feature's domain). Freeze its
  domain API first (barrel export review); downstream features consume
  only the barrel from this point on.
- Acceptance: downstream diffs are import-line-only; kernel version bump
  is the single coordination point.

### Phase 5 — Mid-layer packages (~1–2 days each)

- `reminders`, then `notes` (depend on kernel domain only).
- Acceptance: same as Phase 3.

### Phase 6 — Aggregators + core split (~2–3 days)

- `home` (aggregates kernel + reminders), `account` (touches people +
  reminders + subscriptions) last, when their dependencies are stable
  packages.
- Split `lib/core/` behind `core_*` packages (auth, subscriptions,
  observability) or keep one `core` package — decide by Phase 6 kickoff
  ADR; not blocking features.
- Delete `lib/features/`; the app package holds only `main.dart`,
  router, and DI wiring.
- Acceptance: `lib/features/` gone, CI (analyze, tests, R1–R5 — extended
  to `packages/`, coverage, secrets, budgets) all green.

## CI evolution per phase

| Phase | CI change |
| --- | --- |
| 0 | Coverage script accepts `packages/` paths |
| 1 | R5 exemption removed (root provider gone) |
| 2 | R4 forbids cross-feature presentation imports |
| 3–6 | `check_layer_boundaries.py` + coverage scan `packages/*/lib/src/`; graph generator scans `packages/` |
| 6 | `publish_to: none` + `melos`/`very_good` workspace orchestration if package count justifies it |

## Rollback rule

Each phase PR must be independently revertible (no cross-phase file
moves in one PR). If a phase breaks the coverage gate, revert the phase
PR — never lower the gate.
