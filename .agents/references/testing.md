# Testing

Runner: `fvm flutter test` (root shell) or `melos test` (all packages).
Targeted: `melos test:people` (or `cd packages/house_mira_people &&
flutter test`). Coverage: per-package `flutter test --coverage`
(writes `packages/*/coverage/lcov.info` plus root `coverage/lcov.info`).

## Coverage gate (CI-enforced)

`.github/workflows/ci.yml` requires **100% line coverage per file** for
every file under `packages/*/lib/**/domain/` or
`packages/*/lib/**/application/`.
Any new use case, entity branch, or service line must come with a test
in the owning package's `test/`.

## Patterns

- **Cubit tests** (`bloc_test`): assert emitted state sequences.
  Fake services by subclassing (e.g. `_FakeAuthService extends AuthService`
  with `stubUser`/`signInError` fields), not mocktail, when the class is
  mockable-by-subclass.
- **Mocktail** (`Mock`, `when`, `verify`): for Supabase clients and
  platform plugins. Named args need `any(named: 'value')` /
  `captureAny(named: ...)`.
- **Widget tests**: pump with `AppLocalizations.localizationsDelegates`
  + `supportedLocales`; find text/icons; tap buttons; assert fake recorded
  the call. Narrow-screen overflow checks: set
  `tester.view.physicalSize` (and reset in tearDown) before pumping.
- Widget tests that need app-shell assets (`assets/images/…`) or goldens
  (`test/goldens/`) stay in the root suite (`test/`); packages own only
  asset-free unit/cubit tests. The app shell owns all image assets.
- Throw only `Exception`/`Error` instances in fakes (`only_throw_errors`).
- Async test setup: `await` everything; `unawaited()` only for
  intentionally fire-and-forget calls (`import 'dart:async'`).

## What to test

- New cubit method → state-sequence tests incl. cancel + failure paths.
- New use case/entity branch → unit test (coverage gate).
- New button/callback wiring → widget test tapping it.
- Bug fix → regression test reproducing it first.
