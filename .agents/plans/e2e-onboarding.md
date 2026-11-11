# E2E plan — Onboarding, daily on GitHub Actions

Status: implemented through phase 2 (suite green in `flutter test` + `e2e list`); CI job
written but not yet run against GitHub — see §9.
Framework: [e2e](https://e2e.com/docs/mobile) (`e2e` + `@e2e-dev/mobile`, Playwright-shaped APIs
driving a real simulator/emulator through `agent-device`).
Reference sample: [e2e-inc/e2e · examples/with-flutter](https://github.com/e2e-inc/e2e/tree/main/examples/with-flutter)
(Flutter 3.47 / e2e 0.22 — same major versions as this repo).

## Decisions (locked)

| Question | Decision |
| --- | --- |
| Platform v1 | Android emulator first. iOS simulator job is phase 3, same suite, no test rewrite. |
| Device source | GitHub-hosted (`reactivecircus/android-emulator-runner` on `ubuntu-latest`, KVM). Hosted-device provider (Limrun/BrowserStack) stays a drop-in swap via `mobile({ device: provider })` if flake cost outweighs the setup. |
| Credentials | Reuse `SUPABASE_URL_PROD`/`SUPABASE_PUBLISHABLE_KEY_PROD`, aliased to `*_E2E` at job level. Onboarding is pre-auth and writes nothing, and no dedicated project exists yet. Any auth/write suite moves to its own project first. |
| App changes | Allowed: `Semantics(identifier:)` locators + `--dart-define=E2E_MODE=true` (kills infinite hero animations and page-transition duration on e2e builds only). |
| Test style | Locator-only. No `agent`/`AI_GATEWAY_API_KEY`, so zero model cost and a hard pass/fail signal. |

## 1. The final onboarding suite (what "done" means)

One file, `e2e/tests/onboarding.e2e.ts`, five tests, run on every target. Each test starts
from a clean device so "first launch" is real:

```ts
test.beforeEach(async ({ app }) => {
  await app.clearState();  // wipes shared_preferences (onboarding_completed)
  await app.open();
});
```

| # | Test | Asserts |
| --- | --- | --- |
| 1 | first launch shows slide 1 | `onboarding-slide-1` visible, `onboarding-skip` visible, `onboarding-cta-next` visible, `onboarding-cta-finish` absent |
| 2 | Next walks all three slides | tap CTA → `onboarding-slide-2` → tap → `onboarding-slide-3` + `onboarding-cta-finish` present and `onboarding-cta-next` gone |
| 3 | Skip jumps to last slide | tap `onboarding-skip` → `onboarding-slide-3` visible + `onboarding-cta-finish` present |
| 4 | Get Started completes onboarding | from slide 3 tap `onboarding-cta-finish` → home shell visible ("Home" tab), all `onboarding-slide-*` gone |
| 5 | completion survives a cold restart | after test 4's flow, `app.restart()` → home again, `onboarding-slide-1` never appears (proves `completeOnboarding()` persisted, not just navigated) |

Plus one guard test that pins the *negative* contract (cheap, catches a real regression class):

| # | Test | Asserts |
| --- | --- | --- |
| 6 | Skip does not persist completion | tap Skip → slide 3 → `app.restart()` → `onboarding-slide-1` visible again |

Why these: the gate lives in `main.dart` (`datasource.isOnboardingCompleted()` →
`_defaultInitialLocation`) and the flag is written only by `OnboardingPage._handleComplete`.
Tests 4–6 are the only ones that prove the wiring end to end; 1–3 prove the three-slide
contract that `test/features/onboarding/*` already pins at widget level, now on a real device.

Post-onboarding anchor is the shell's home tab in the bottom nav, matched by
role plus a `/^Home/` name regex (`navHome` in `app_en.arb`) — not home content
and not an exact text match: home needs a backend and onboarding does not, and
Flutter names the tab node `Home\nTab 1 of 5`.

Deferred (documented, not v1):

- swipe-between-slides (needs an explicit gesture/swipe API pass — `screen` locators have no
  `scrollIntoView`/`setInputFiles` on devices; confirm whether `locator.swipe` or
  `mobileTools` `swipe` is the supported call before adding).
- "onboarding never shows again after Skip+Get Started from slide 1" (matrix variant of 3+5).
- iOS/Android visual parity via `toHaveScreenshot`.

## 2. App changes required (small, no behavior change in shipped builds)

### 2.1 Semantics identifiers

Flutter ids come from `Semantics(identifier:)`; a tappable must merge so id + `button` role
land on one node (`MergeSemantics`). Currently none of the onboarding widgets expose ids.

| File | Change |
| --- | --- |
| `packages/house_mira_onboarding/lib/presentation/views/onboarding_header_widget.dart` | wrap the skip `TextButton` in `MergeSemantics(child: Semantics(identifier: 'onboarding-skip', button: true, child: …))` |
| `packages/house_mira_onboarding/lib/presentation/views/onboarding_footer_widget.dart` | same wrapper around the gradient `InkWell`; id is state-carrying: `onboarding-cta-next` while `!isLastPage`, `onboarding-cta-finish` on the last page. Label still comes from `AppLocalizations` (a11y unchanged). |
| `packages/house_mira_onboarding/lib/presentation/views/onboarding_page_widget.dart` | new `required String identifier` param; wrap in `Semantics(identifier: identifier, container: true, child: SingleChildScrollView…)` |
| `packages/house_mira_onboarding/lib/presentation/views/onboarding_view.dart` | pass `identifier: 'onboarding-slide-${index + 1}'` to `OnboardingPageWidget` |
| `packages/house_mira_onboarding/lib/presentation/views/onboarding_progress_widget.dart` | optional: `Semantics(identifier: 'onboarding-progress', value: '${currentPage + 1}/$pageCount')` so dot state is assertable without pixel checks |

Two ids for the CTA is deliberate: advancing and finishing are different behaviors, and it
keeps the suite free of localized-text matching for the state transition (English copy can
change without touching the e2e suite; localized text stays a secondary assertion).

### 2.2 `E2E_MODE` build flag

Problem: `OnboardingFamilyHeroWidget`/`RemindersHero`/`SecurityHero` run `_FloatAnimation`
and `_PulseAnimation` as `repeat(reverse: true)` forever. A permanently animating screen is
the documented cause of an overrun/wedged iOS XCUITest runner, and it makes every snapshot
race the animation.

- Add `packages/house_mira_core/lib/config/build_flags.dart`:
  `const e2eMode = bool.fromEnvironment('E2E_MODE');` (single seam, documented like
  `AppConfig`; not a secret, so no env JSON entry).
- `_FloatAnimation`/`_PulseAnimation`: when `e2eMode`, return `child` without an
  `AnimationController` (release the ticker, exact same layout).
- `_onSkip`/`_onNext`: `Duration.zero` instead of 400 ms in e2e mode.
- Default stays `false`; `flutter test` and shipped builds are untouched.

Both changes are covered by the existing gate: `fvm flutter analyze` + `fvm flutter test`
(the onboarding widget tests in `test/features/onboarding/` already assert copy, dot width
and tap-to-advance, so a bad `Semantics` wrapper surfaces immediately).

## 3. e2e project layout

```
e2e/
  package.json          # private, type: module, devDeps: e2e, @e2e-dev/mobile, typescript, @types/node
  package-lock.json     # committed (npm ci in CI)
  tsconfig.json
  e2e.config.ts
  tests/onboarding.e2e.ts
  README.md             # how to run locally on an emulator
  .gitignore            # node_modules, .e2e/
```

Root-level ignores are not needed: `e2e/.gitignore` covers `node_modules/` and `.e2e/`.

`e2e.config.ts` (mirrors the sample, minus the agent block):

```ts
import type { E2EConfig } from 'e2e';
import { mobile } from '@e2e-dev/mobile';

// The installed build: applicationId in android/app/build.gradle.kts and
// PRODUCT_BUNDLE_IDENTIFIER in ios/Runner.xcodeproj.
const app = { bundleId: 'com.housemira.app' };

export default {
  targets: [
    { name: 'android', engine: mobile({ platform: 'android' }), app },
    { name: 'ios', engine: mobile({ platform: 'ios' }), app }, // phase 3
  ],
  workers: 1,
} satisfies E2EConfig;
```

Notes

- Install happens in the workflow (`adb install -r`) rather than `app.appPath` +
  `device.installApp()`: one place to see the artifact, and `e2e doctor` validates the
  bundle id is installed.
- No replay cache to commit while the suite is locator-only (`agent` steps are what the cache
  replays).
- `e2e/` is outside `packages/**`, so melos, `dart analyze`, the boundary scripts and the
  secrets scan ignore it. Keep it that way — no `.dart` files there.

## 4. GitHub Actions workflow

New file `.github/workflows/e2e-daily.yml`. Daily + manual, never on PRs in v1 (a 20-minute
emulator job on every PR is a bad trade; PR gating is a later decision).

```yaml
name: E2E (daily)

on:
  schedule:
    - cron: '0 4 * * *'   # 04:00 UTC = 01:00 BRT
  workflow_dispatch:

concurrency:
  group: e2e-daily
  cancel-in-progress: false

env:
  E2E_TELEMETRY_DISABLED: '1'

jobs:
  android-onboarding:
    name: Android — onboarding
    runs-on: ubuntu-latest
    timeout-minutes: 60
    env:
      SUPABASE_URL_E2E: ${{ secrets.SUPABASE_URL_PROD }}
      SUPABASE_PUBLISHABLE_KEY_E2E: ${{ secrets.SUPABASE_PUBLISHABLE_KEY_PROD }}
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: temurin

      - uses: subosito/flutter-action@v2
        with:
          flutter-version-file: .fvmrc

      - uses: actions/setup-node@v4
        with:
          node-version: '24'
          cache: npm
          cache-dependency-path: e2e/package-lock.json

      - name: Install dependencies
        run: flutter pub get

      - name: Build release APK for e2e
        run: >
          flutter build apk --release
          --dart-define=APP_FLAVOR=dev
          --dart-define=E2E_MODE=true
          --dart-define=SUPABASE_URL=$SUPABASE_URL_E2E
          --dart-define=SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY_E2E

      - name: Install test dependencies
        working-directory: e2e
        run: npm ci

      - name: Enable KVM
        run: |
          echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666", OPTIONS+="static_node=kvm"' \
            | sudo tee /etc/udev/rules.d/99-kvm4all.rules
          sudo udevadm control --reload-rules
          sudo udevadm trigger --name-match=kvm

      - name: Run e2e on emulator
        uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 35
          target: google_apis
          arch: x86_64
          disable-animations: true
          emulator-options: -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect
          script: |
            adb install -r build/app/outputs/flutter-apk/app-release.apk
            cd e2e
            npx e2e doctor
            npx e2e run --target android --reporter list,junit --max-failures 3

      - name: Upload e2e report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: e2e-android
          path: e2e/.e2e/
          retention-days: 14
```

Key details, all from the docs' mobile-CI contract:

- **Release build.** Not required by the framework — debug, profile and release all run the
  suite (verified 6/6 in each). Release is chosen because it is the only build type with
  `isMinifyEnabled`/`isShrinkResources` in this repo, so a missing `proguard-rules.pro` keep
  rule fails here instead of shipping. Profile is the faster local loop. Signing falls back to
  debug keys when `android/key.properties` is absent (`android/app/build.gradle.kts`), which
  is exactly what an emulator needs — no keystore secrets in this workflow.
- **Emulator is booted by the action**, so a boot failure is a distinct step failure instead
  of a mysterious `APP_UNREACHABLE`.
- **`disable-animations: true`** (system animator scales → 0) + `E2E_MODE` (Flutter-side
  infinite animations) are complementary, not redundant.
- **`--reporter list,junit`** writes `.e2e/junit.xml`; the artifact bundle also holds
  `report.json` and per-test trace pages + screenshots, which is what makes a red nightly
  actionable without a rerun.
- CI defaults: `workers: 1`, `retries: 1` (a test that only passes on retry is reported as
  flaky — that's the signal we want from a nightly).
- Optional later: `--video` on the nightly run for an MP4 per test; leave it off initially
  (artifact size).

### iOS job (phase 3)

`runs-on: macos-15`, `flutter build ios --simulator` (debug: the simulator rejects
`--release`/`--profile` — `supportsSimulator` is true only for `BuildMode.debug` in Flutter
3.47's `build_info.dart`; the e2e docs' "release simulator `.app`" line is React Native
advice), then:

```bash
UDID=$(xcrun simctl create e2e-iphone \
  com.apple.CoreSimulator.SimDeviceType.iPhone-16 \
  com.apple.CoreSimulator.SimRuntime.iOS-18-5)   # pick a runtime the image ships
xcrun simctl boot "$UDID"
xcrun simctl install "$UDID" build/ios/iphonesimulator/Runner.app
cd e2e && npx e2e run --target ios --reporter list,junit
```

- Pin the runtime by UDID: the accessibility tree shifts between iOS releases, so an image
  update must not silently break locators.
- Cache `~/.agent-device/apple-runner/derived` only (agent-device builds its XCUITest runner
  there). Never cache all of `~/.agent-device` — a restored daemon state wedges the next run.

## 5. Secrets

**Nothing to add.** The workflow reuses the existing prod credentials via
job-level aliases:

| Job env | Comes from |
| --- | --- |
| `SUPABASE_URL_E2E` | `secrets.SUPABASE_URL_PROD` |
| `SUPABASE_PUBLISHABLE_KEY_E2E` | `secrets.SUPABASE_PUBLISHABLE_KEY_PROD` |

Acceptable because onboarding is pre-auth and local-only: the keys exist solely to
satisfy the fail-fast startup chain (`AppConfig` → `Supabase.initialize` → Remote
Config → RevenueCat), and no test reads or writes server state. The `*_E2E` names are
kept as a seam: the day a dedicated e2e/dev project exists, only those two lines in
`e2e-daily.yml` change. Any suite that authenticates or writes must do that first.

RevenueCat keys are optional in `AppConfig` (billing init is skipped when empty), so the e2e
build needs none. `APP_FLAVOR=dev` also needs no separate secret: `env/dev.json` and the
committed `google-services.json` / `GoogleService-Info.plist` cover it. Note the flavor is
inert in a release build anyway — `AppFlavor` is read only by two `kDebugMode` gates
(`useTestStore`, diagnostics) and as a trace attribute, so it does not select a backend.

## 6. Phases

| Phase | Work | Exit criteria |
| --- | --- | --- |
| **P0 – seams** | Semantics ids (2.1), `E2E_MODE` (2.2), root `.gitignore`, `e2e/` project skeleton + config | `fvm flutter analyze` clean, `fvm flutter test` green, `python3 tool/check_feature_boundaries.py` clean |
| **P1 – local green** | `tests/onboarding.e2e.ts` (tests 1–3), run on a local emulator with a `dev` build | `npx e2e run --target android` passes twice in a row without `--no-cache` |
| **P2 – the two that matter** | tests 4–6 (completion, restart persistence, skip-not-persisted) | same, plus one deliberate run with the `completeOnboarding()` call commented out must fail test 4/5 |
| **P3 – CI nightly** | `e2e-daily.yml` android job, secrets, artifact upload | workflow green from `workflow_dispatch`, then green unattended on the first cron |
| **P4 – iOS** | iOS target job + pinned runtime, cache `apple-runner/derived` | both jobs green on the same day |
| **P5 – widen** | second feature (login or reminders create-flow), `--changed-since`/filters if PR runs are wanted | suite still under 5 min of wall-clock test time |

## 7. Risks / open items

1. **Emulator boot flake on GitHub-hosted runners** is the dominant failure mode. Mitigation:
   boot in its own action step, `disable-animations`, `timeout-minutes: 60`, retries left at
   the CI default of 1 so flake shows up in the report as `flaky` rather than hiding.
2. **Startup chain is real.** Every launch does Supabase/Remote Config/RevenueCat init over
   the network; a bad e2e project key fails *every* test with `APP_UNREACHABLE`. The first
   assertion after `app.open()` therefore needs headroom (splash → session recovery →
   onboarding). Concretely: give the `onboarding-slide-1` assertion a 20 s timeout, and give
   the post-`app.restart()` assertion the same.
3. **Locale.** Assertions lean on ids; the only text-ish assertion is the home
   tab's name, matched as `/^Home/` because Flutter appends `Tab 1 of 5`. If a
   device ever boots non-English that anchor breaks — pin the emulator locale
   (`-prop persist.sys.language=en`) rather than localizing the suite.
4. **System dialogs sit over the app.** The notification permission prompt
   appears on the first frame of a fresh install; `app.permissions`
   pre-grants it. Any future runtime permission (camera, location) needs the
   same treatment, or tests fail on a dialog they never see in the report
   summary.
5. **`E2E_MODE` is a behavior fork in prod code.** It is compile-time only, defaults off, and
   only skips animation — keep it that way; never gate real logic (persistence, navigation,
   routing) behind it, or the suite stops testing the shipped path.
6. **Onboarding copy is owned by `app_en.arb`.** Adding ids now avoids a churn bill when the
   copy changes; text-based locators would have made every copy edit a red nightly.
7. **Confirmed later:** the swipe-between-slides test needs the supported gesture API. Not a
   blocker for v1.
8. **The suite authenticates against the prod project.** Fine while it is locator-only and
   pre-auth (onboarding writes nothing), but it is a standing constraint: the first test that
   signs in, inserts, or deletes turns a green nightly into prod data churn. Move §5's two
   alias lines to a dedicated project *before* writing that test.

## 8. Out of scope

- PR/push triggers and required-check gating (nightly first, gate after a month of greens).
- Agent (`agent.act`/`agent.assert`) steps and the AI Gateway key.
- Screenshot/golden parity between platforms.
- Hosted device services.
- Anything backend-mutating: no account creation, no family/reminder writes.

## 9. What exists now

| File | State |
| --- | --- |
| `packages/house_mira_core/lib/config/build_flags.dart` | new: `BuildFlags.e2eMode` (`bool.fromEnvironment('E2E_MODE')`) |
| `packages/house_mira_onboarding/lib/presentation/views/onboarding_header_widget.dart` | `MergeSemantics` + `onboarding-skip` |
| `…/onboarding_footer_widget.dart` | `MergeSemantics` + `onboarding-cta-next` / `onboarding-cta-finish` |
| `…/onboarding_page_widget.dart` | new `identifier` param, `Semantics(container: true)` |
| `…/onboarding_view.dart` | passes `onboarding-slide-N`; `jumpToPage` under `E2E_MODE` |
| `…/onboarding_hero_widget.dart` | float/pulse tickers skipped under `E2E_MODE` |
| `test/features/onboarding/onboarding_semantics_test.dart` | new: pins every identifier the suite uses |
| `e2e/` | `package.json`, `package-lock.json`, `tsconfig.json`, `e2e.config.ts`, `tests/onboarding.e2e.ts`, `README.md`, `.gitignore` |
| `.github/workflows/e2e-daily.yml` | Android job: release APK + KVM emulator + `e2e run` + artifact |

Verification run locally:

- `fvm flutter analyze` → 0 errors, 0 warnings (info-level `directives_ordering` noise in untouched files predates this work).
- `fvm flutter test test/features/onboarding/` → 11 passed, also green with `--dart-define=E2E_MODE=true` (exercises the `jumpToPage` branch and the null-controller path).
- `fvm flutter test` → the only failures are 9 pre-existing golden diffs in `test/core/widgets/sand/sand_golden_test.dart` and `test/theme/theme_golden_test.dart`; reproduced on a stashed pristine tree, so unrelated.
- `python3 tool/check_feature_boundaries.py` / `check_layer_boundaries.py` (Python ≥ 3.10; this machine's default `python3` is 3.9 and crashes on the annotation syntax) → both hold.
- `bash tool/check_no_hardcoded_secrets.sh` → clean.
- `cd e2e && npx tsc` → no output (suite + config typecheck against the real API).
- `cd e2e && npx e2e list --target android` → all six tests discovered.
- `fvm flutter build apk --debug --dart-define=E2E_MODE=true --dart-define-from-file=env/dev.json` → the README build command line parses and builds.
- `cd e2e && npx e2e run --target android` on an Android 15 emulator → **6 passed / 6** in
  **release** (84 s), **profile** (38 s) and **debug** (95 s), all built with `E2E_MODE=true`.

Two findings from that device run, both fixed in the suite:

1. `main.dart` asks for notification permission in a post-frame callback, so a
   fresh install raises the system dialog over onboarding and every tap lands on
   it (all six tests failed with `no node`). Fixed with
   `app.permissions: { notifications: 'grant' }` — `deny` is not enough on
   Android, it revokes and the OS asks again.
2. `BottomNavigationBar` exposes a tab as one node named `Home\nTab 1 of 5`, so
   the post-onboarding anchor is `getByRole('button', /^Home/)` rather than
   `getByText('Home')`.

Dependency note: the sample pins `e2e ^0.22.0` + `@e2e-dev/mobile ^0.12.5`, but `0.12.6` (what the caret resolves to) declares a peer of `e2e >=0.22.1`, which only `0.23.0` satisfies. The pair here is `e2e ^0.23.0` + `@e2e-dev/mobile ^0.12.6`, locked in `package-lock.json`. `ai` is an *optional* peer and is deliberately not installed — no agent steps.

Still to do, in order:

1. `workflow_dispatch` the job once; if the emulator boot flakes, that is the known trade-off in §7. No secrets to add — the job aliases prod (§5).
2. Run once on a local emulator (`e2e/README.md`) to confirm the six tests on the device, not just in `flutter test` — the widget tests prove the identifiers exist, not that `getByTestId` reads them off the accessibility tree.
3. Only then add the iOS job (§4) and start considering PR gating.
