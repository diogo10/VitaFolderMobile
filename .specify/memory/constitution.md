# VitaFolderMobile Constitution

## Core Principles

### I. Flutter toolchain (FVM + very_good_analysis)
The project MUST use Flutter 3.41.6 managed exclusively via FVM
(`.fvmrc`), and all CLI commands MUST be prefixed with `fvm`
(never bare `flutter`/`dart`):
`fvm flutter pub get`, `fvm flutter analyze`,
`fvm flutter test`, `fvm flutter test --coverage`.
Lint set MUST be `very_good_analysis` with `public_member_api_docs` off
(`analysis_options.yaml`); CI runs `dart analyze --fatal-warnings` and
`flutter analyze --no-fatal-infos --fatal-warnings` (infos allowed).
After a change, `fvm flutter analyze` MUST report `No issues found!`
(0 errors, 0 warnings). Fix lints; never add `ignore` comments.
**Rationale:** Single toolchain and strict lints keep local and CI builds
consistent and reviewable.

### II. Feature-first clean architecture (4 layers)
Code MUST live under `lib/features/<feature>/` with `domain/`, `data/`,
`application/`, and `presentation/` subfolders; shared code lives in
`lib/core/`. Concrete examples: `lib/features/reminders/domain`,
`lib/features/reminders/application`, `lib/features/people/data`,
`lib/features/people/presentation`. Add a layer only when needed.
Details: `.agents/references/architecture.md`.
**Rationale:** Feature ownership with explicit layer boundaries allows
independent evolution of UI and data sources.

### III. State management (Cubit only)
All business logic and UI state MUST be handled using `flutter_bloc`
Cubits — one Cubit per presentation concern under
`lib/features/<feature>/presentation/cubit/`. States MUST be a sealed
class hierarchy (`*_state.dart`); each Cubit method MUST emit `Loading`
first then exactly one outcome state. Services MUST be constructor-
injected; no Supabase imports in cubits and MUST never leak
`AuthException`/Supabase errors to widgets — translate to states.
Cancelled flows (e.g. Google returns `null`) emit the neutral state,
not a failure. UI stays logic-less; state changes trigger via Cubit
methods. Details: `.agents/references/cubit.md`.
**Rationale:** Predictable unidirectional data flow with testable,
UI-ready states.

### IV. Backend infrastructure (Supabase)
The application MUST use Supabase (`supabase_flutter`) as the sole
backend service provider. Auth flows live in
`lib/core/auth/auth_service.dart`; data access lives in `data/`
repositories/datasources with injected `SupabaseClient` (production
default `Supabase.instance.client`, mocks in tests). Edge-function
source lives in `supabase/functions/<name>/` (`delete-account`,
`resend-email-v1`), documented in `README.md`. Details:
`.agents/references/supabase.md`.
**Rationale:** Standardizes database, authentication, and storage
interfaces behind injectable boundaries.

### V. Dependency injection (GetIt)
All services, repositories, and Cubits MUST be registered via GetIt,
wired per feature in
`lib/core/injections/<feature>/*_service_locator.dart` (sl cascades),
aggregated in `lib/core/injections/service_locator.dart`. Inject via
constructor; never call `GetIt.instance` directly in widgets. Tests
pass fakes/mocks through constructors.
**Rationale:** Decouples creation from usage and enables easy mocking.

### VI. Type-safe error handling (Either only, never fake data)
Repository methods MUST return `Future<Either<Failure, T>>` (`fpdart`,
`lib/core/errors/failure.dart`) — Either of Failure or success only,
never custom exceptions across the boundary. Map Supabase errors to
`Failure` at the repository boundary; external calls wrap in
try/catch (`on Object`, never bare `catch`). Entities are hand-written
immutable classes: `final` fields, `const` constructor, `copyWith`,
`from(dynamic json)` returning `null` on bad input, `==`/`hashCode`.
Never fall back to defaults on parse/validation failure (no silent
current-time, empty-string, or placeholder fallbacks) — return `null`.
Explicit failure beats wrong data. No code generation for models
(`flutter gen-l10n` is the only generator in use).
**Rationale:** Failures stay explicit, typed, and display-safe.

### VII. Localization, naming, async
Displayed text MUST go via AppLocalizations backed by
`lib/l10n/app_en.arb` (and `lib/l10n/app_pt.arb`) — never hardcode
user-visible strings. Naming: suffix View, Widget, Cubit, State,
Usecase, Entity, Repository, Service, ServiceLocator; files are
`snake_case`. Async: `await` inside `async` functions; sync callbacks
either become `async` with `await` or use `unawaited` for
fire-and-forget. Catch with `on Object` (never bare, never narrow
silently).
**Rationale:** Shippable in two locales with consistent, greppable code.

## Constraints

*   **Coverage gate (CI-enforced):** `fvm flutter test --coverage`
    (writes `coverage/lcov.info`) plus
    `python3 tool/check_business_logic_coverage.py` MUST report 100%
    per file under `lib/**/domain/` and `lib/**/application/`. Every
    new use case, entity branch, or service line ships with a test.
*   **Secrets gate (CI-enforced):**
    `bash tool/check_no_hardcoded_secrets.sh` MUST pass. No backend
    credentials in `lib/`: Supabase URL/key arrive via dart-define
    flags (`APP_FLAVOR`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`)
    through `AppConfig.fromEnvironment` in
    `lib/core/config/app_config.dart`; startup throws `StateError` on
    missing/invalid values — never add fallbacks. Local: copy
    `env/<flavor>.example.json` to sibling `env/<flavor>.json`, then
    `fvm flutter run --dart-define-from-file=env/dev.json`. Real env
    JSON files are gitignored and CI rejects them if committed. Never
    expose service-role keys; `test/` fakes stay on reserved example
    hosts with mock anon keys (see `test/widget_test.dart`).
*   **Testing:** New code ships with tests — cubit state sequences
    (including cancel and failure paths, `bloc_test`), unit tests for
    use-case and entity branches (coverage gate), widget tests for
    button wiring (pump with AppLocalizations delegates). Bug fix →
    regression test first. Throwaway repro tests go in the system temp
    directory outside the repo, never in `test/`. Details:
    `.agents/references/testing.md`, `.github/workflows/ci.yml`.
*   **Navigation:** `go_router` only (`lib/core/router/`).
*   **Layer isolation:** Domain MUST NOT import from Data or
    Presentation.

## Development Workflow

*   **Setup:** `fvm flutter pub get`.
*   **Verify (in order):** `fvm flutter analyze` → `No issues found!`;
    `fvm flutter test` → `All tests passed!`;
    `fvm flutter test --coverage` + coverage script (business-logic
    change only) → 100% per file.
*   **Feature modularization:** New features group by
    `lib/features/<feature>/` with only the layers needed
    (`domain/`, `data/`, `application/`, `presentation/`).
*   **Spec-kit templates:** `.specify/templates/` are Flutter-targeted
    (Dart/Flutter version, `fvm` commands, feature-first paths) and
    carry localization + `Either<Failure, T>` failure checklists in
    spec/plan/tasks.

## Governance & Amendments

*   **Source of truth:** `AGENTS.md` plus `.agents/references/` govern
    daily rules; this constitution mirrors them for spec-kit gates.
    On conflict, `AGENTS.md` wins and this document MUST be amended
    to match before merging gated work.
*   **Testing enforcement:** Pull Requests MUST NOT be merged if they
    fail existing tests, break `fvm flutter analyze`, trip either
    gate script, or decrease total code coverage. Documentation-only
    PRs (markdown under `.specify/`, `*.md` docs with no `lib/` or
    `test/` changes) are exempt from the test/coverage gates.
*   **Constitutional amendments:** Changes to core principles (e.g.,
    Flutter version upgrades or library swaps) MUST be proposed via a
    'RFC' Pull Request and require approval from at least two lead
    maintainers.
*   **Policy review:** This document SHOULD be reviewed at the start of
    every major release cycle to ensure the technology stack remains
    optimal.

**Version**: 1.1.0 | **Ratified**: 2026-09-28 | **Last Amended**: 2026-09-28
