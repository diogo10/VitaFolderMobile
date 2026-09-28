# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Stack**: Dart / Flutter 3.41.6 via FVM — all commands `fvm`-prefixed

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel
- **[Story]**: User story this task belongs to
- Include the exact file path in every code task (feature-first: `lib/features/<feature>/{domain,data,application,presentation}/`, DI in `lib/core/injections/`)

## Phase 1: Setup

- [ ] T001 Create feature structure per implementation plan (`lib/features/<feature>/...` + DI in `lib/core/injections/<feature>/*_service_locator.dart` aggregated in `lib/core/injections/service_locator.dart`)

## Phase 2: Foundational

- [ ] T002 [P] Add AppLocalizations keys to `lib/l10n/app_en.arb` + `lib/l10n/app_pt.arb` ([keys]); no hardcoded user-visible strings
- [ ] T003 [Blocking prerequisites, e.g. Supabase table/RLS + `AppConfig` dart-define wiring; run `fvm flutter run --dart-define-from-file=env/dev.json`]

## Phase 3: User Story 1 (Priority: P1)

- [ ] T010 [P] [US1] Entity + repo interface in `lib/features/<feature>/domain/` (`from` returns null on bad input; repo returns `Future<Either<Failure, T>>`)
- [ ] T011 [P] [US1] Repository impl in `lib/features/<feature>/data/` (map Supabase errors to `Failure` at boundary; `on Object` catch)
- [ ] T012 [US1] Cubit + sealed states in `lib/features/<feature>/presentation/cubit/` (`Loading` first, then exactly one outcome; cancel → neutral state; no Supabase imports)
- [ ] T013 [US1] View/widgets in `lib/features/<feature>/presentation/` (AppLocalizations only; `isLoading` into buttons; small `*_widget.dart` sections)
- [ ] T014 [US1] Tests: cubit state sequences incl. cancel + failure (`bloc_test`); use-case/entity unit tests (coverage gate); widget test tapping buttons (pump with AppLocalizations delegates)

## Phase N: Polish & Cross-Cutting Concerns

- [ ] TXXX [P] Failure-path audit: every `Left(Failure)` maps to a distinct UI state; no fake-data fallbacks
- [ ] TXXX Run gates in order: `fvm flutter analyze` (No issues found!) → `fvm flutter test` (All tests passed!) → `fvm flutter test --coverage` + `python3 tool/check_business_logic_coverage.py` (100% per file under `lib/**/domain/`, `lib/**/application/`) → `bash tool/check_no_hardcoded_secrets.sh`
- [ ] TXXX Documentation updates (spec/plan/tasks + README section if edge function, secrets, or deploy steps changed)
