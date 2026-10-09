# ADR-0002: Dependency injection with GetIt and `instanceName`

- Status: Accepted
- Date: 2026-10-08
- Source: `.agents/references/architecture.md`, `lib/core/injections/`

## Context

Feature graphs (repositories, use cases, cubits) and core singletons
(`AuthService`, `EdgetFunctions`, observability) need one wiring place
per feature that tests can bypass by passing fakes through constructors.
Unnamed GetIt lookups by type alone do not scale once several features
register the same generic types (repository interfaces, use cases).

## Decision

- Use `GetIt` via the shared `slInstance` in
  `lib/core/injections/service_locator.dart`.
- Wire each feature in its own
  `lib/core/injections/<feature>/*_service_locator.dart` (cascading `sl`
  calls), aggregated by `ServiceLocator.init()`. Example:
  `lib/core/injections/people/people_service_locator.dart`.
- Register **every** entry with an explicit `instanceName` (lowerCamelCase,
  e.g. `'authService'`, `'peopleRepositoryImpl'`, `'getPeopleUsecase'`,
  `'peopleCubit'`) and resolve with the matching name. The generic type
  parameter may be explicit or inferred — both
  `sl<AuthService>(instanceName: 'authService')` and
  `sl(instanceName: 'getPeopleUsecase')` occur in the tree (e.g.
  `lib/core/router/app_router.dart`,
  `lib/core/injections/people/people_service_locator.dart`); the
  `instanceName` itself is always explicit, never omitted.
- Inject via constructors everywhere. Never call `GetIt.instance` /
  `slInstance` directly in widgets or cubits — resolution happens in
  service locators, router default factories
  (`lib/core/router/app_router.dart`), and the `lib/main.dart`
  composition root. Legacy exceptions (do not copy):
  `lib/features/people/presentation/widgets/people_loaded_widget.dart`
  and `lib/features/onboarding/presentation/pages/onboarding_page.dart`.
- Register tab cubits as lazy singletons; one-shot cubits
  (`FamilySettingsCubit`, `InvitePeopleCubit`, `CreateReminderCubit`, …)
  are **not** registered — the route's default factory builds them fresh
  per visit.
- Tests pass fakes/mocks through constructors and never touch GetIt.

## Consequences

- Adding a dependency means: register it with an `instanceName` in the
  feature locator, inject it through the consumer's constructor, resolve
  it by name at the composition root.
- Name collisions across features are avoided only if names stay globally
  unique; consider a lint/grep check. Renaming a name requires updating
  every resolution site.
- Widgets stay DI-free, which keeps widget tests to constructor injection.

## References

- `lib/core/injections/service_locator.dart`
- `lib/core/injections/people/people_service_locator.dart`
- `lib/core/router/app_router.dart` (default factories resolving by name)
- `lib/main.dart` (composition root resolving by name at startup)

## Code-review checklist

- [ ] Every registration and every resolution passes an explicit
      `instanceName` (generic type parameter explicit or inferred)?
- [ ] Consumer takes the dependency via constructor (no `GetIt` import
      in widgets/cubits — except the two documented legacy exceptions)?
- [ ] Tab cubit registered lazy-singleton; one-shot cubit built fresh in
      the route factory, not registered?
- [ ] Tests inject fakes via constructors, no GetIt reset/setup?
