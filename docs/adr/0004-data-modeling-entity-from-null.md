# ADR-0004: Data modeling — `entity.from()` returns `null` on invalid input

- Status: Accepted
- Date: 2026-10-08
- Source: `AGENTS.md` ("Error handling — never fake data"),
  `.agents/references/architecture.md`

## Context

Backend rows can arrive malformed (wrong shape, missing columns). Coping
strategies that invent data — current-time fallbacks, empty-string
stand-ins, placeholder entities — produce wrong UI that looks right and
is hard to trace. Explicit failure beats wrong data.

## Decision

- Entities are hand-written immutable classes: `final` fields, `const`
  constructor, `copyWith`, `==`/`hashCode`, annotated `@immutable`.
  Canonical example: `PersonEntity` in
  `lib/features/people/domain/entities/person_entity.dart`.
- Parsing entry points are nullable: `static Entity? from(dynamic json)`
  returns `null` on any invalid input (non-map shape, unusable payload)
  instead of throwing or fabricating defaults:

  ```dart
  static PersonEntity? from(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    return PersonEntity(...);
  }
  ```

- Callers treat `null` as "row unusable" (skip, filter, or map to
  `Failure` per ADR-0003) — never substitute a placeholder entity.
- No code generation for models (`build_runner` is a leftover dev
  dependency); l10n via `flutter gen-l10n` is the only generator in use.

## Consequences

- New entities ship with unit tests for every `from()` branch: valid
  input, wrong-shape input → `null`, plus `copyWith`/`==` coverage
  (100% per-file coverage gate on `domain/`, see
  `.agents/references/testing.md`).
- Repositories filter or fail on `null` parses; lists never contain
  half-built entities.
- `ReminderModel.fromMap` (throwing `FormatException` on unknown type)
  predates this rule: new parsing code follows the nullable `from()`
  pattern; align the legacy model when it is next touched.

## References

- `lib/features/people/domain/entities/person_entity.dart`
- `lib/features/reminders/domain/entities/reminder_entity.dart`
- `lib/features/notes/domain/entities/note_entity.dart`
- `tool/check_business_logic_coverage.py`

## Code-review checklist

- [ ] New entity immutable (`final` fields, `const` ctor, `copyWith`,
      `==`/`hashCode`, `@immutable`)?
- [ ] `from()` returns `null` on invalid input — no time/empty-string
      fallbacks, no placeholders?
- [ ] Callers handle the `null` (skip/filter/fold to `Failure`)?
- [ ] Unit tests cover every `from()` branch (coverage gate holds)?
