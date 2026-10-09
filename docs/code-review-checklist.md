# Code-Review Checklist

Paste the relevant sections into the PR description or review comments.
Every item derives from an ADR or the playbook — the link is the appeal
path when reviewer and author disagree.

## Must-pass on every PR

- [ ] `fvm flutter analyze` → No issues found; `fvm flutter test` →
      All tests passed ([playbook §4](playbook/mobile-playbook.md#4-testing-expectations-summary)).
- [ ] No hardcoded secrets / Supabase URLs / `service_role` in `lib/`
      (`tool/check_no_hardcoded_secrets.sh`).
- [ ] Naming: `*View`, `*Widget`, `*Cubit`, `*State`, `*Usecase`,
      `*Entity`, `*Repository`, `*Service`, `*ServiceLocator`;
      files `snake_case`.

## Routing ([ADR-0001](adr/0001-routing-go-router.md))

- [ ] No raw string route path outside `app_routes.dart`.
- [ ] Route args use a typed `*Route` wrapper; unknown extras ignored,
      never crash.
- [ ] Redirect-matrix change covered by `resolveAppRedirect` unit tests.
- [ ] Shared tab cubit via `BlocProvider.value`; one-shot screen via
      `BlocProvider(create:)` with a fresh instance per call.

## DI ([ADR-0002](adr/0002-dependency-injection-getit.md))

- [ ] Every registration/resolution passes explicit `instanceName`
      (type parameter explicit or inferred).
- [ ] Constructor injection only — no `GetIt` import in widgets/cubits
      (except the two legacy exceptions documented in ADR-0002).
- [ ] Tab cubits lazy-singleton; one-shot cubits unregistered, built
      fresh in route factory.
- [ ] Tests inject fakes via constructors, no GetIt setup.

## Errors ([ADR-0003](adr/0003-error-handling-either-failure.md))

- [ ] Repository methods return `Future<Either<Failure, T>>`.
- [ ] SDK errors mapped to `Left(Failure…)` at the boundary
      (`on Failure` + `on Object`, no bare `catch`).
- [ ] Zero-row writes → `WriteBlockedFailure`, never success.
- [ ] Callers fold both sides — no silent defaults, no leaked SDK types.

## Data modeling ([ADR-0004](adr/0004-data-modeling-entity-from-null.md))

- [ ] Entities immutable (`final`, `const`, `copyWith`, `==`/`hashCode`,
      `@immutable`).
- [ ] `from()` returns `null` on invalid input — no fallbacks or
      placeholders.
- [ ] Callers handle the `null` (skip/filter/fold to `Failure`).
- [ ] Unit tests cover every `from()` branch (coverage gate holds).

## Localization ([ADR-0005](adr/0005-localization-l10n-only.md))

- [ ] No new hardcoded user-visible strings.
- [ ] Keys added to both `app_en.arb` and `app_pt.arb`.
- [ ] Widget tests provide localization delegates + supported locales.

## State + boundaries + concurrency ([playbook](playbook/mobile-playbook.md))

- [ ] One Cubit per concern; sealed states; `Loading` first then exactly
      one outcome state.
- [ ] Distinct failure state per UI-distinguishable case; cancel emits
      the neutral state, not failure.
- [ ] No Supabase imports in cubits (`grep` check in playbook §2).
- [ ] Services injected; side effects delegated, exceptions translated
      to states.
- [ ] `await` in `async` fns; sync callbacks use `unawaited` only for
      true fire-and-forget (`import 'dart:async'`).
- [ ] `on Object catch`, never bare `catch`, never narrow-silently.

## Tests for this PR

- [ ] New cubit method → state-sequence tests incl. cancel + failure.
- [ ] New use-case/entity branch → unit test (coverage gate).
- [ ] New button/callback → widget test tapping it.
- [ ] Bug fix → regression test reproducing it first.
