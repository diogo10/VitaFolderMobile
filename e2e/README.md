# HouseMira device E2E (e2e.com)

Black-box suite that drives an **installed** build on an Android emulator or an
iOS simulator. It is not part of `fvm flutter test`; the Flutter suites stay the
fast layer, this one proves the shipped binary works on a device.

Plan and rationale: [`.agents/plans/e2e-onboarding.md`](../.agents/plans/e2e-onboarding.md).
Framework docs: [e2e.com/docs/mobile](https://e2e.com/docs/mobile).

## Layout

```
e2e.config.ts        targets (bundle id com.housemira.app), workers: 1
tests/*.e2e.ts       one file per feature; locators only, no agent/AI steps
```

Locators come from `Semantics(identifier:)` in the app, not from visible copy:

| Identifier | Where |
| --- | --- |
| `onboarding-slide-1`…`3` | `OnboardingPageWidget` (`Semantics(container: true)`) |
| `onboarding-skip` | `OnboardingHeaderWidget` |
| `onboarding-cta-next` / `onboarding-cta-finish` | `OnboardingFooterWidget`, id carries the state |

They are pinned by `test/features/onboarding/onboarding_semantics_test.dart`, so
moving one fails fast in `flutter test` instead of on a device.

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

**No new secrets needed.** The job aliases the existing prod credentials at job
level and uses the `*_E2E` names below:

```yaml
SUPABASE_URL_E2E: ${{ secrets.SUPABASE_URL_PROD }}
SUPABASE_PUBLISHABLE_KEY_E2E: ${{ secrets.SUPABASE_PUBLISHABLE_KEY_PROD }}
```

That is acceptable only because onboarding is pre-auth and writes nothing: the
credentials exist to satisfy the fail-fast startup chain (`AppConfig` →
`Supabase.initialize` → Remote Config → RevenueCat), not to read data. A suite
that signs in, inserts, or asserts on server state must point those two lines at
a dedicated project instead — do not build one on the prod project.

RevenueCat keys are optional in `AppConfig` and are not needed here: billing
init is skipped when they are empty, and onboarding is pre-auth. `APP_FLAVOR=dev`
with prod credentials is intentional and inert in a release build: the flavor is
read only by two `kDebugMode` gates and as a trace attribute, so it never changes
which backend the release APK talks to.

## Rules

- **Locators only.** No `agent.act` / `agent.assert` in this project: the suite
  must be free and deterministic. Add the agent layer deliberately if it is ever
  wanted (`AI_GATEWAY_API_KEY`, replay cache committed).
- **Never seed via UI shortcuts.** Tests always start from `app.clearState()`;
  a test that depends on another test's state is a bug.
- **Assert ids, not copy.** Copy lives in `app_en.arb`/`app_pt.arb`; the only
  text assertion allowed is a navigation anchor (`Home`).
