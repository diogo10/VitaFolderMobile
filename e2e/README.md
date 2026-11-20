# HouseMira device E2E (e2e.com)

Black-box suite that drives an **installed** build on an Android emulator or an
iOS simulator. It is not part of `fvm flutter test`; the Flutter suites stay the
fast layer, this one proves the shipped binary works on a device.

Plan and rationale: [`.agents/plans/e2e-onboarding.md`](../.agents/plans/e2e-onboarding.md).
Framework docs: [e2e.com/docs/mobile](https://e2e.com/docs/mobile).

## Layout

```
e2e.config.ts        targets (bundle id com.housemira.app), workers: 1
ci-android.sh        device run for CI: pre-checks, install, doctor, run
tests/*.e2e.ts       one file per feature; locators only, no agent/AI steps
```

Locators come from `Semantics(identifier:)` in the app, not from visible copy:

| Identifier | Where |
| --- | --- |
| `onboarding-slide-1`…`3` | `OnboardingPageWidget` (`Semantics(container: true)`) |
| `onboarding-skip` | `OnboardingHeaderWidget` |
| `onboarding-cta-next` / `onboarding-cta-finish` | `OnboardingFooterWidget`, id carries the state |
| `account-email-field` / `account-password-field` | `AccountNoAccountAuthWidget` (`SandLabeledField`) |
| `account-sign-in-button` | `AccountNoAccountAuthWidget` (`SandPrimaryButton`) |
| `account-login-error` | `AccountView`, on the failed sign-in snackbar |
| `account-loaded` | `AccountLoadedWidget`, the signed-in anchor |

The onboarding ids and the three login-form ids are pinned by
`test/features/onboarding/onboarding_semantics_test.dart` and
`packages/house_mira_account/test/presentation/views/account_login_semantics_test.dart`,
so moving one fails fast in `flutter test` instead of on a device.

## Run locally (Android)

```bash
# 1. Build an e2e build. E2E_MODE kills the infinite hero animations;
#    env/dev.json already supplies APP_FLAVOR plus the Supabase keys.
fvm flutter build apk --release \
  --dart-define=E2E_MODE=true \
  --dart-define-from-file=env/dev.json

# 2. Boot an emulator, then install that exact build.
fvm flutter emulators
adb install -r build/app/outputs/flutter-apk/app-release.apk

# 3. Run the suite (Node 22.22.3+, 24.8+ or 26+).
cd e2e
npm install
npx e2e doctor
npx e2e run --target android
```

`--dart-define-from-file` and explicit `--dart-define` flags can be mixed only
when they do not repeat a key; here `env/dev.json` supplies the Supabase and
RevenueCat keys, the two defines above add flavor and the e2e switch.

Reports land in `e2e/.e2e/` (gitignored): `report.json`, `junit.xml` and
`results/` with the trace page and screenshots per test.

## Build mode: release, profile, or debug

All three work — the suite drives an installed build and does not care which
mode produced it. Measured on the same Android 15 emulator, same six tests:

| Mode | APK | Suite | What it adds |
| --- | --- | --- | --- |
| `--release` | 66.7 MB | 6/6, 84 s | R8 + resource shrinking; what users get |
| `--profile` | 97.0 MB | 6/6, 38 s | AOT, standalone, no minification |
| `--debug` | 178 MB | 6/6, 95 s | nothing extra; slowest cold start |

The CI job uses **release** for one reason only: in this repo `release` is the
only build type with `isMinifyEnabled`/`isShrinkResources` on
(`android/app/build.gradle.kts`, plus `proguard-rules.pro`), so a missing keep
rule in a plugin would pass a profile run and ship broken. `profile` is the
better local loop (faster build, faster run); `debug` buys nothing and starts
slowest.

The e2e docs' "make a Release build" rule is aimed at React Native/Expo, where
a debug build loads its JS from Metro and opens on an error screen. Flutter
debug/profile APKs are self-contained, so the rule does not bind us.

Four numbers from one machine, one run each: treat them as indicative, not a
benchmark.

## Two things the first device run taught us

- **The notification prompt owns the screen on a fresh install.** `main.dart`
  requests notification permission in a post-frame callback, so the system
  dialog appears on top of onboarding and every tap lands on it. The target's
  `app.permissions` pre-grants it (`notifications: 'grant'`) because `deny` on
  Android only revokes and the OS asks again. Without that, all six tests fail
  with `no node (match count 0)` and a screenshot of the dialog.
- **The home tab is not reachable by text.** Flutter's `BottomNavigationBar`
  exposes each tab as one node named `Home\nTab 1 of 5`, so the post-onboarding
  anchor is `getByRole('button', /^Home/)`, not `getByText('Home')`.

## What a green run looks like

Verified on an Android 15 emulator, app built with `E2E_MODE=true` — 6/6 in
release, profile and debug (see the table above for timings):

```
✓ |android| tests/onboarding.e2e.ts (6 tests)
Test Files  1 passed (1)
     Tests  6 passed (6)
```

An `E2E_MODE` build is not required to pass — without it the suite still runs,
but the heroes animate forever and the page transitions are 400 ms, which is
slower and flakier on a cold emulator.

## Login suite

`tests/login.e2e.ts` covers the three email/password paths. The app has no
standalone login route: a signed-out account tab is the login screen, so each
test completes onboarding, taps the `Account` tab and waits for
`account-email-field`.

| Test | Input | Assertion |
| --- | --- | --- |
| Invalid email | `not-an-email` | `account-login-error` appears, form stays, `account-loaded` absent |
| Invalid password | valid email + wrong password | same error and form assertions |
| Valid login | `E2E_LOGIN_EMAIL` + `E2E_LOGIN_PASSWORD` | `account-loaded` appears, sign-in form gone |

The valid account is declared in `e2e.config.ts` as the framework's
`credentials.login` entry. The test fills `credentials.user('login').password`,
an opaque handle: the runner types it, masks the field, and redacts it from
reports and traces. The `process.env` read is only used to decide whether the
credential tests can run; if either variable is unset they skip with a reason,
so onboarding-only local runs still work. CI does not rely on that skip: a
preflight step fails when either variable is missing.

### Credentials in CI

This repository's scheduled pipeline is GitHub Actions, not GitLab. The GitLab
CI/CD variables from the task map to repository secrets:

1. Settings → Secrets and variables → Actions → New repository secret.
2. Add `E2E_LOGIN_EMAIL` (the dedicated test account's email).
3. Add `E2E_LOGIN_PASSWORD` (its password).
4. Keep the account dedicated to e2e: the login suite reads the profile and
   never writes family data, but a shared human account would make runs
   nondeterministic.

They are passed to the runner as job-level env in `.github/workflows/e2e-daily.yml`.
The same names work locally:

```bash
E2E_LOGIN_EMAIL='e2e@example.test' E2E_LOGIN_PASSWORD='…' \
  npx e2e run --target android tests/login.e2e.ts
```

## iOS

The iOS simulator is **debug-only** in Flutter 3.47: `flutter build ios
--simulator` defaults to debug and rejects `--release`/`--profile` with
`"<MODE> mode is not supported for simulators."` (`supportsSimulator` is true
only for `BuildMode.debug` in `build_info.dart`). The e2e docs' "release
simulator `.app`" line is React Native advice and does not apply here, so the
`--dart-define` switches do the work instead of a release build:

```bash
fvm flutter build ios --simulator \
  --dart-define=E2E_MODE=true \
  --dart-define-from-file=env/dev.json
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
npx e2e run --target ios
```

## CI

`.github/workflows/e2e-daily.yml` runs the Android target nightly at 04:00 UTC
(01:00 BRT) and on demand. It builds the release APK with the e2e switch, boots
an emulator in its own step, and uploads `.e2e/` even when a test fails.

The device work itself is `e2e/ci-android.sh`, called as one line
(`script: bash e2e/ci-android.sh`). That is not style: the emulator action runs
**every line** of its `script:` input in its own `/usr/bin/sh -c`, so a `cd e2e`
on one line does not apply to the next. Every nightly from 2026-11-12 to 11-15
failed exactly that way — the suite ran at the repo root, found no
`e2e.config.ts` and exited `CONFIG_NOT_FOUND` two seconds after boot. The script
resolves its own directory, so the caller's cwd cannot break it, and it fails
fast (with a `::error::` annotation) when the CLI, config, APK or booted device
is missing.

Two more guards keep a red run honest:

- the CLI is `e2e/node_modules/.bin/e2e` from `npm ci`, never `npx e2e`: with no
  local install `npx` silently downloads the latest release, so a broken install
  becomes an unreviewed CLI upgrade;
- `doctor`, `list` and `run` all pass `--target android`: `doctor` checks every
  configured target by default and would fail on the iOS target on an ubuntu
  runner. A pre-emulator step runs `e2e list --target android` so a config or
  resolution problem surfaces in seconds, and `ci-android.sh` asserts
  `.e2e/junit.xml` exists after a passing run, so a green job cannot be one that
  never produced a report.

The artifact upload is best effort: the job verdict comes from the run step, so
the upload warns instead of failing when it finds nothing. Two details keep that
honest and useful:

- `include-hidden-files: true` is required — the bundle lives in `.e2e/`, and
  `actions/upload-artifact@v4` skips hidden paths by default. Without it the
  2026-11-17 nightly uploaded nothing (and went red) after the suite had passed
  6/6 and written `.e2e/junit.xml`;
- the report check lives in `ci-android.sh`, not in the upload step, so a run
  that produces no report fails while naming the missing file.

Run the same script locally with the emulator booted and the APK built:

```bash
bash e2e/ci-android.sh
```

**Onboarding needs no new secrets.** The job aliases the existing prod
credentials at job level and uses the `*_E2E` names below:

```yaml
SUPABASE_URL_E2E: ${{ secrets.SUPABASE_URL_PROD }}
SUPABASE_PUBLISHABLE_KEY_E2E: ${{ secrets.SUPABASE_PUBLISHABLE_KEY_PROD }}
```

The credentials exist to satisfy the fail-fast startup chain (`AppConfig` →
`Supabase.initialize` → Remote Config → RevenueCat). The login suite adds two
required repository secrets, `E2E_LOGIN_EMAIL` and `E2E_LOGIN_PASSWORD`; the
workflow's preflight step fails, before the emulator boots, if any of the four
is empty.

The login suite only authenticates and reads the signed-in profile. It does not
insert, update, or delete family data, and it uses a dedicated test account. A
dedicated Supabase project is still the right target before adding write tests
(or if auth traffic on prod is not acceptable): change the two alias lines to
`secrets.SUPABASE_URL_E2E` / `secrets.SUPABASE_PUBLISHABLE_KEY_E2E` — the job
already uses those names — and seed the test account there.

RevenueCat keys are optional in `AppConfig` and are not needed in e2e builds:
billing init is skipped when they are empty. `APP_FLAVOR=dev` with prod
credentials is intentional and inert in a release build: the flavor is read only
by two `kDebugMode` gates and as a trace attribute, so it never changes which
backend the release APK talks to.

## Rules

- **Locators only.** No `agent.act` / `agent.assert` in this project: the suite
  must be free and deterministic. Add the agent layer deliberately if it is ever
  wanted (`AI_GATEWAY_API_KEY`, replay cache committed).
- **Never seed via UI shortcuts.** Tests always start from `app.clearState()`;
  a test that depends on another test's state is a bug.
- **Assert ids, not copy.** Copy lives in `app_en.arb`/`app_pt.arb`; the only
  text assertion allowed is a navigation anchor (`Home`).
