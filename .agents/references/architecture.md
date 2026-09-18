# Architecture

Feature-first, layered. `lib/features/<feature>/` owns its code;
`lib/core/` holds shared infrastructure.

## Feature layers

| Layer | Contains | Example |
| --- | --- | --- |
| `domain/` | Entities (`*Entity`), repository interfaces, use cases (`*Usecase` with `call()`), utils | `reminders/domain/usecase/get_reminder_usecase.dart` |
| `data/` | Repository implementations, models, datasources (Supabase, local) | `people/data/repository/people_repository_impl.dart` |
| `application/` | Services orchestrating across repositories | `reminders/application/reminder_notification_service.dart` |
| `presentation/` | Views, widgets, cubits (`cubit/`, `views/`, `widgets/`, `screens/`) | `account/presentation/cubit/account_cubit.dart` |

Not every feature has every layer — add one only when needed.

## Core (`lib/core/`)

`auth/` (AuthService, Google handler), `injections/` (GetIt setup),
`router/` (go_router), `local_storage/`, `functions/` (edge-function
client), `errors/` (`Failure`), `widgets/sand/` (design system),
`analytics/`, `network/`.

## Dependency injection

GetIt, wired per feature in `lib/core/injections/<feature>/*_service_locator.dart`
(sl cascades), aggregated in `service_locator.dart`. Inject via constructor;
never call `GetIt.instance` directly in widgets (one legacy exception exists
in people — don't copy it). Tests pass fakes/mocks through constructors.

## Data conventions

- Repository methods return `Future<Either<Failure, T>>` (fpdart).
  Map Supabase errors to `Failure` at the repository boundary.
- Entities are hand-written immutable classes: `final` fields,
  `const` constructor, `copyWith`, `from(dynamic json)` returning
  `null` on bad input, `==`/`hashCode`, annotated `@immutable`.
- No code generation for models (build_runner is a leftover dev
  dependency — l10n via `flutter gen-l10n` is the only generator in use).
