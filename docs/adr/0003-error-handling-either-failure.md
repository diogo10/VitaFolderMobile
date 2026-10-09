# ADR-0003: Error handling with `Either<Failure, T>`

- Status: Accepted
- Date: 2026-10-08
- Source: `AGENTS.md`, `.agents/references/architecture.md`,
  `lib/core/errors/failure.dart`

## Context

Supabase errors, RLS-filtered writes, and parse failures must surface as
explicit, typed outcomes — never as thrown raw SDK errors in the UI layer
and never as silent fallbacks. See also the "never fake data" rule in
`AGENTS.md`.

## Decision

- Repository methods return `Future<Either<Failure, T>>` (fpdart):
  `Right` for success, `Left(Failure)` for any failure. Examples:
  `lib/features/reminders/domain/repository/reminder_repository.dart`,
  `lib/features/reminders/data/repository/reminder_repository_impl.dart`.
- Map Supabase/SDK errors to `Failure` **at the repository boundary**:
  `on Failure catch (e)` → `Left(Failure(message: e.message))`,
  `on Object catch` → `Left(Failure())` (log with `debugPrint`/logger at
  the site). Cubits and views never handle raw Supabase exceptions.
- Use `WriteBlockedFailure` for writes the backend accepted but that
  changed zero rows (e.g. RLS-filtered update/delete) — surface as error,
  never success (`lib/core/errors/failure.dart`).
- Consumers fold explicitly (`result.fold(onFailure, onSuccess)`); no
  default-value fallbacks that mask failure.

## Consequences

- Every new repository method comes with success + failure-path tests.
- `Failure.message` is the only error text that flows upward; user-facing
  wording is chosen in presentation via l10n, not in repositories.
- Narrow `catch` clauses that swallow errors silently are banned; catch
  with `on Object` and map to `Failure` or a cubit state.

## References

- `lib/core/errors/failure.dart`
- `lib/features/reminders/domain/repository/reminder_repository.dart`
- `lib/features/reminders/data/repository/reminder_repository_impl.dart`
- `lib/features/notes/data/repository/notes_repository_impl.dart`

## Code-review checklist

- [ ] New repository method returns `Future<Either<Failure, T>>`?
- [ ] All SDK/parse errors mapped to `Left(Failure…)` at the boundary
      (`on Failure` + `on Object`, no bare `catch`)?
- [ ] Zero-row writes return `WriteBlockedFailure`, not success?
- [ ] Caller folds both sides — no silent defaults, no leaked SDK types?
