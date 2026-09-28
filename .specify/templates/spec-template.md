# Feature Specification: [FEATURE NAME]

**Feature Branch**: `[###-feature-name]`
**Created**: [DATE]
**Status**: Draft
**Stack**: Dart / Flutter 3.41.6 via FVM (`fvm flutter ...`)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - [Brief Title] (Priority: P1)

[Describe this user journey in plain language]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

### Edge Cases

- What happens when [boundary condition]?
- Cancel path: [e.g. Google sign-in returns null] → neutral state, not failure.
- Failure path: [e.g. repository returns `Left(Failure)`] → distinct failure state per UI case.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST [specific capability]

### Feature-first paths

List every touched layer (add a layer only when needed):

- `lib/features/<feature>/domain/` — entities (`*Entity`), repo interfaces, usecases (`*Usecase.call()`)
- `lib/features/<feature>/data/` — repo impls, models, datasources (Supabase mapped to `Failure` at boundary)
- `lib/features/<feature>/application/` — cross-repository services
- `lib/features/<feature>/presentation/` — views, `*_widget.dart`, `cubit/` (`*_cubit.dart`, `*_state.dart`)
- `lib/core/` shared: [e.g. `injections/<feature>/`, `errors/failure.dart`, `l10n/`]
- DI: register in `lib/core/injections/<feature>/*_service_locator.dart`, aggregate in `lib/core/injections/service_locator.dart`

### Localization checklist

- [ ] All user-visible strings via AppLocalizations (`lib/l10n/app_en.arb` + `lib/l10n/app_pt.arb`) — no hardcoded strings
- [ ] New ARB keys added in both locales: [list keys]

### Either failure checklist

- [ ] Repository methods return `Future<Either<Failure, T>>` (fpdart) — no thrown domain exceptions, no fallbacks
- [ ] Supabase errors mapped to `Failure` at the repository boundary
- [ ] Entity `from(dynamic json)` returns `null` on bad input (never fake data)
- [ ] Cubit translates `Left(Failure)` to a distinct failure state; sealed states; `Loading` first, then exactly one outcome; no Supabase imports in cubits

### Key Entities *(include if feature involves data)*

- **[Entity]**: [What it represents; fields; `copyWith`/`from` null-on-bad-input notes]

## Success Criteria *(mandatory)*

- **SC-001**: [Measurable metric]
- **SC-002**: `fvm flutter analyze` clean (0 errors, 0 warnings); `fvm flutter test` passes; business-logic files under `lib/**/domain/` + `lib/**/application/` at 100% per-file coverage (`fvm flutter test --coverage` + `python3 tool/check_business_logic_coverage.py`); `bash tool/check_no_hardcoded_secrets.sh` passes
