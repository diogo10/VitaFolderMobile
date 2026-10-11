# Architecture

Melos workspace. `packages/house_mira_<feature>/lib/` owns its code
(independently versioned, CODEOWNERS-owned);
`packages/house_mira_core/lib/` holds shared infrastructure;
`lib/` is the app composition root only (main.dart, core/router/*,
core/injections/service_locator.dart).

## Feature layers

| Layer | Contains | Example |
| --- | --- | --- |
| `domain/` | Entities (`*Entity`), repository interfaces, use cases (`*Usecase` with `call()`), utils | `packages/house_mira_reminders/lib/domain/usecase/get_reminder_usecase.dart` |
| `data/` | Repository implementations, models, datasources (Supabase, local) | `packages/house_mira_people/lib/data/repository/people_repository_impl.dart` |
| `application/` | Services orchestrating across repositories | `packages/house_mira_reminders/lib/application/reminder_notification_service.dart` |
| `presentation/` | Views, widgets, cubits (`cubit/`, `views/`, `widgets/`, `screens/`) | `packages/house_mira_account/lib/presentation/cubit/account_cubit.dart` |

Not every feature has every layer — add one only when needed.
Each package's public API is `lib/house_mira_<feature>.dart` (domain
only); import rules P1–P6 are enforced by
`tool/check_feature_boundaries.py` (no cross-package data/ imports,
core never imports features, feature-to-feature via domain/ only).

## Core (`packages/house_mira_core/lib/`)

`auth/` (AuthService, Google handler), `router/` (route table),
`local_storage/`, `functions/` (edge-function client), `errors/`
(`Failure`), `widgets/sand/` (design system), `analytics/`, `network/`,
`theme/`, `l10n/` + `generated/`, `notifications/` (cross-feature
contracts like `NotificationSender`).

## Dependency injection

GetIt, wired per feature in the feature package's
`lib/*_service_locator.dart` (cascades), aggregated in the app's
`lib/core/injections/service_locator.dart`. Inject via constructor;
never call `GetIt.instance` / `slInstance` in widgets, pages, or cubits —
resolution happens in service locators, router `*Factory` seams
(`lib/core/router/app_router.dart`), and `lib/main.dart`. Widget/page
tests pass fakes through constructors; router tests use the factory
seams. Layer rules R1–R5 are enforced by
`tool/check_layer_boundaries.py` (lib/) and P1–P6 by
`tool/check_feature_boundaries.py` (packages/) — see ADR-0006.

## Data conventions

- Repository methods return `Future<Either<Failure, T>>` (fpdart).
  Map Supabase errors to `Failure` at the repository boundary.
- Entities are hand-written immutable classes: `final` fields,
  `const` constructor, `copyWith`, `from(dynamic json)` returning
  `null` on bad input, `==`/`hashCode`, annotated `@immutable`.
- No code generation for models (build_runner is a leftover dev
  dependency — l10n via `flutter gen-l10n` is the only generator in use).
