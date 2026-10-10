# ADR-0006: Feature packages with explicit public APIs and enforced layer boundaries

- Status: Accepted
- Date: 2026-10-10
- Source: `tool/check_layer_boundaries.py`, `tool/generate_dependency_graph.py`,
  `docs/architecture/dependency-graph.md`,
  `docs/architecture/modularization-migration-plan.md`
- Supersedes (in part): ADR-0002's legacy GetIt-in-widget exceptions —
  both are removed by this ADR (people `PeopleLoadedWidget`, onboarding
  `OnboardingPage`); the rest of ADR-0002 still stands.

## Context

The app is a single package (`house_mira`) with a feature-first layout:
8 features under `lib/features/` (account, home, login, notes, onboarding,
paywall, people, reminders), 186 Dart files in `lib/` (~29k LOC, ~22k in
features). The audit for this ADR found the layout healthy in structure
but unenforced at the boundaries:

- State management is mixed: `flutter_bloc` dominates (12 cubits, 34 files)
  but `package:provider` leaked into two reminders widgets, and
  `AuthStateNotifier` (core) extends `ChangeNotifier`.
- Two widgets resolved dependencies via GetIt directly
  (`PeopleLoadedWidget`, `OnboardingPage`), against the constructor-injection
  rule, forcing widget tests to set up GetIt.
- Domain entities imported `package:flutter/foundation.dart` (for
  `@immutable`) and the notes color palette exposed Flutter `Color` maps
  from `domain/` — so "pure domain" was convention, not fact.
- Cross-feature imports exist (10 edge groups, see
  `docs/architecture/dependency-graph.md`): `people` domain is the shared
  kernel (family/identity), `home` aggregates `people` + `reminders` at the
  domain level, and three widgets reuse `FamilyHeaderWidget` across
  features. Nothing enforces which layer may depend on which.
- The 100%-per-file `domain/`+`application/` coverage gate
  (`tool/check_business_logic_coverage.py`) must keep passing through every
  extraction step — it matches on path substrings, so moving business logic
  between packages must move its tests with it.

Multi-package extraction (one Dart package per feature) is the long-term
goal for build parallelism, explicit APIs, and independent versioning, but
doing it in one big-bang PR would break the coverage gate and reviewability.

## Decision

1. **One package per feature is the target; `lib/features/<feature>/` is
   the staging ground.** No code moves to real packages in this ADR. Each
   future package exposes an explicit public API: domain entities,
   repository interfaces, and use cases only (`src/` layout with a barrel
   export; presentation stays private to the package except documented
   shared widgets). Until extraction, treat deep imports as the API:
   depending on another feature's `data/` is already forbidden (R4).
2. **Domain has zero Flutter/Supabase imports — enforced, not aspirational.**
   - `@immutable` comes from `package:meta` (added as a direct
     dependency), never `package:flutter/foundation.dart`.
   - Flutter types (e.g. `Color` palettes) live in `presentation/`; domain
     keeps only plain-Dart validation (`noteColorFrom`, allowlists).
   - Supabase imports live in `data/` repositories/datasources,
     `core/auth/`, `core/functions/`, and the two composition roots
     (`main.dart`, `core/injections/service_locator.dart`) — nowhere else.
3. **No service location inside features.** `get_it` / `service_locator`
   imports and `GetIt.instance` / `slInstance` calls are banned under
   `lib/features/` (R3). Widgets and pages receive dependencies via
   constructors; the router's `*Factory` seams (default: GetIt by name,
   override: constructor-injected fakes) are the only widget-adjacent
   resolution points. Both ADR-0002 legacy exceptions are removed:
   `PeopleLoadedWidget`/`PeopleView` take `LocalStorageDatasource`, and
   `OnboardingPage` takes `OnboardingLocalDatasource`.
4. **One state-management framework: `flutter_bloc`.** No
   `package:provider` imports under `lib/features/` (R5). The single root
   `Provider<AuthService>` in `main.dart` is grandfathered until migration
   Phase 1 replaces it with a `flutter_bloc`-provided scope.
5. **Boundaries are checked in CI, not in reviews' heads.**
   `tool/check_layer_boundaries.py` (rules R1–R5) runs in CI next to the
   coverage gate and fails the PR on violation. The dependency graph is
   generated (`tool/generate_dependency_graph.py --write`) and checked in
   at `docs/architecture/dependency-graph.md`; edge changes must come with
   a regenerated graph.
6. **Extraction is phased per the migration plan** (`docs/architecture/
   modularization-migration-plan.md`): harden → publish API surface →
   extract leaf packages first (`login`, `onboarding`, `paywall`) → kernel
   (`people`) → aggregators (`home`, `account`) → delete the monolith
   paths. Every phase keeps `flutter analyze` clean and the 100%
   domain/application coverage gate green.

## Consequences

- New code can only depend inward (presentation → application → domain →
  core) and only on another feature's domain. Violations fail CI with the
  rule number and file — no human has to memorize the matrix.
- Adding a cross-feature dependency means: depend on the other feature's
  domain, regenerate the dependency graph, and (post-extraction) add a
  `path`/published dependency — never copy the file.
- Widgets stay DI-free, so widget tests construct with fakes and never
  touch GetIt; router tests use the `*Factory` seams.
- The coverage gate keeps working unchanged during hardening (paths stay
  under `lib/`); extraction phases must extend the gate's path filter to
  the new package locations before moving files (plan Phase 0).
- `package:meta` is now a direct dependency (pure-Dart `@immutable`).

## References

- `docs/architecture/modularization-migration-plan.md` (phased extraction)
- `docs/architecture/dependency-graph.md` (current edges, generated)
- `tool/check_layer_boundaries.py` (R1–R5 enforcement, CI-gated)
- `tool/generate_dependency_graph.py` (graph generator)
- `lib/core/router/app_router.dart` (`*Factory` seams, default GetIt
  resolution at the composition root)
- `lib/main.dart` (`MyApp` factory seams)

## Code-review checklist

- [ ] New cross-feature import targets another feature's `domain/` only
       (R4 — CI enforces; `dependency-graph.md` regenerated)?
- [ ] No `package:flutter*` import in `domain/` (R1)?
- [ ] No `supabase` import outside `data/`, `core/auth|functions`, or the
       two composition roots (R2)?
- [ ] No `get_it`/`service_locator` import and no `GetIt.instance` /
       `slInstance` call under `lib/features/` (R3)?
- [ ] No `package:provider` import under `lib/features/` (R5)?
- [ ] New widget/page takes dependencies via constructor; route adds a
       `*Factory` seam with a GetIt default instead of widget-side
       resolution?
- [ ] Business-logic move carries its tests (coverage gate still 100%
       per file)?
