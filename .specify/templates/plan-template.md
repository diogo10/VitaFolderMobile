# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]

## Summary

[Primary requirement + technical approach]

## Technical Context

**Language/Version**: Dart / Flutter 3.41.6 via FVM (`.fvmrc`; all commands `fvm`-prefixed)
**Primary Dependencies**: `flutter_bloc` (Cubits), `get_it` (`lib/core/injections/service_locator.dart`), `go_router`, `supabase_flutter`, `fpdart` (`Either<Failure, T>`)
**Storage**: [e.g. Supabase table(s) + RLS notes; else N/A — data access in `data/`, mapped to `Failure` at boundary]
**Testing**: `fvm flutter test` (+ scoped `fvm flutter test test/features/<feature>`); coverage `fvm flutter test --coverage` + `python3 tool/check_business_logic_coverage.py` (100% per file under `lib/**/domain/`, `lib/**/application/`); secrets `bash tool/check_no_hardcoded_secrets.sh`
**Target Platform**: [iOS / Android]
**Lint**: `very_good_analysis` (`public_member_api_docs` off); verify `fvm flutter analyze` → `No issues found!`
**Config/Secrets**: `AppConfig.fromEnvironment` (`APP_FLAVOR`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`); local run `fvm flutter run --dart-define-from-file=env/dev.json`; never hardcode keys/URLs/service_role in `lib/`
**Localization**: AppLocalizations via `lib/l10n/app_en.arb` + `lib/l10n/app_pt.arb`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*
See `.specify/memory/constitution.md` (mirrors `AGENTS.md`).

- [ ] Feature-first paths identified (`lib/features/<feature>/{domain,data,application,presentation}` + `lib/core/` shared); DI via `lib/core/injections/service_locator.dart`
- [ ] Cubit design: sealed states, `Loading` first then exactly one outcome, services injected, no Supabase imports in cubits
- [ ] Error design: `Either<Failure, T>` only at repo boundary; entity `from` null-on-bad-input; no fake-data fallbacks
- [ ] Localization: ARB keys planned for EN + PT, no hardcoded strings
- [ ] Gates planned: analyze / test / 100% business-logic coverage / no-hardcoded-secrets

## Project Structure

```text
specs/[###-feature]/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
└── tasks.md

lib/features/<feature>/
├── domain/        # entities, repo interfaces, usecases
├── data/          # repo impls, models, datasources
├── application/   # services (only when needed)
└── presentation/  # views, widgets, cubit/
```

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g. new application/ layer] | [orchestrates N repos] | [would leak cross-repo logic into cubit] |
