# HouseMira

Home of the HouseMira mobile application. A family management platform. 


## How to Contribute

### Prerequisites

- Install [FVM (Flutter Version Management)](https://fvm.app/documentation/getting-started/installation)
- Run `fvm install` to install the correct Flutter version

### Development Commands

```bash
# Install dependencies
fvm flutter pub get

# Analyze code
fvm flutter analyze

# Run tests
fvm flutter test

# Run tests with coverage
fvm flutter test --coverage

# Update golden baselines (sand design system + theme showcase)
fvm flutter test --update-goldens test/core/widgets/sand test/theme

# Check the 100% domain/application coverage gate locally
python3 tool/check_business_logic_coverage.py

# Check startup/APK performance budgets locally
bash tool/check_performance_budgets.sh

# Generate code (after changing models)
fvm dart run build_runner build --delete-conflicting-outputs

# Watch for changes and regenerate code
fvm dart run build_runner watch --delete-conflicting-outputs
```

### Code Style

- Follow the conventions in `AGENTS.md`
- Use `fvm flutter` instead of `flutter` commands
- Never fallback to default values when parsing fails — always return `null`
- Use generated `l10n` translations for displayed text

### Fonts

The app ships its fonts inside the bundle: nothing is downloaded at runtime,
so release builds never crash on a missing font.

| Family | Use | Weights | Files |
| --- | --- | --- | --- |
| Figtree | Theme/body (`AppConstants.fontFamily`) | 400, 500, 600, 700, 800 | `assets/fonts/Figtree-*.ttf` |
| Outfit | Headings and labels | 500, 600, 700, 800 | `assets/fonts/Outfit-*.ttf` |

Both families come from [Google Fonts](https://fonts.google.com) and are
licensed under the SIL Open Font License 1.1
(`assets/fonts/OFL-Figtree.txt`, `assets/fonts/OFL-Outfit.txt`).

To add a weight or a family:

1. Download the file from Google Fonts and keep the `<Family>-<Weight>.ttf`
   naming.
2. Declare it in the app `pubspec.yaml` under `flutter: fonts:` with the
   matching `weight`.
3. Run `fvm flutter test test/theme/font_bundle_test.dart` — the test fails
   when a declared family or weight does not match the bundled file.

## Environments & secrets (dev/staging/prod)

Each flavor points at a **separate Supabase project** so dev/staging traffic
never touches prod data. No backend credentials live in `lib/` — the app
reads them at startup from compile-time `--dart-define`s via
`AppConfig.fromEnvironment()` (`lib/core/config/`). Missing or invalid values
throw `StateError` immediately so the app never runs against the wrong backend.

| Flavor | Supabase project | Used by |
| --- | --- | --- |
| `dev` | Your dev project (`<dev-project-ref>`) | `flutter run` during development |
| `staging` | Your staging project (`<staging-project-ref>`) | Pre-release verification |
| `prod` | Your prod project (`<prod-project-ref>`) | Store / App Distribution builds |

### Local setup

```bash
# One-time per flavor: copy the template and fill in the real values
# (Supabase dashboard → Project Settings → API → Project URL + publishable key).
cp env/dev.example.json env/dev.json
cp env/staging.example.json env/staging.json
cp env/prod.example.json env/prod.json
```

`env/*.json` (real credentials) is gitignored — only `env/*.example.json`
templates are committed. CI rejects committed `env/*.json` files. Never put a
`service-role` key in these files or anywhere in `lib/`; it is server-only
(edge-function secret).

### Flavored run/build commands

```bash
# Run
fvm flutter run --dart-define-from-file=env/dev.json
fvm flutter run --dart-define-from-file=env/staging.json

# Build
fvm flutter build apk --dart-define-from-file=env/prod.json
fvm flutter build appbundle --dart-define-from-file=env/prod.json
fvm flutter build ipa --dart-define-from-file=env/prod.json

# Equivalent without a file (this is what CI uses, with GitHub secrets):
fvm flutter run \
  --dart-define=APP_FLAVOR=dev \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
```

Tests need no defines: they pump widgets directly with fakes
(`https://mock.supabase.co`, `mock-anon-key`).

### RevenueCat (in-app purchases)

Billing uses the [RevenueCat Flutter SDK](https://www.revenuecat.com/docs/getting-started/installation/flutter)
(`purchases_flutter`), initialized at startup via `SubscriptionService`
(`lib/core/subscriptions/`). One public API key per store, from the
RevenueCat dashboard → Project Settings → API keys → App specific keys:

| Key | Value |
| --- | --- |
| `REVENUECAT_APPLE_API_KEY` | Public Apple key (`appl_…`), used on iOS/macOS |
| `REVENUECAT_GOOGLE_API_KEY` | Public Google key (`goog_…`), used on Android |
| `REVENUECAT_TEST_API_KEY` | Test Store key (`test_…`), used on dev + debug builds only |

All keys are optional `--dart-define`s (already present as empty strings
in `env/*.example.json`). Empty means billing is unconfigured and SDK init
is skipped with a warning — the app still runs, which keeps development
unblocked before the store listings exist. Never hardcode keys in `lib/`;
the CI secrets check (`tool/check_no_hardcoded_secrets.sh`) fails on
`appl_`/`goog_` key literals in Dart source.

Test Store first: create the Test Store in the RevenueCat dashboard
(Apps & providers), add monthly/annual test products attached to the
`housemira_pro` entitlement, and expose them via the `default` offering
(`$rc_monthly`, `$rc_annual`). Dev + debug builds configure the SDK with
the `test_` key automatically (`useTestStore` in `lib/main.dart`);
release builds never use it — init is skipped instead, since the SDK
crashes on purpose with Test Store keys. Never submit a build configured
with the `test_` key.

The paywall catalog comes from live offerings
(`SubscriptionService.getOfferingPrices()` → `PaywallData`): real prices
with the save badge derived from them. When the lookup fails, dev/Test
Store builds fall back to the mocked catalog while production shows the
paywall error with retry — buyers never see fake prices.

Native setup already done: Android `MainActivity` subclasses
`FlutterFragmentActivity` (required by RevenueCat Paywalls) and keeps
`launchMode="singleTop"`; iOS targets 15.0 (above the 13.0 minimum).
Before store submission, enable the In-App Purchase capability in Xcode.

### Firebase options per flavor

There is currently one Firebase project, so `firebaseOptionsFor()`
(`lib/core/config/firebase_options_provider.dart`) resolves every flavor to
`DefaultFirebaseOptions.currentPlatform`. That function is the seam for
per-flavor Firebase apps. To provision separate projects:

1. Create `dev`/`staging` Firebase projects (or apps) in the Firebase console.
2. Generate one options file per project:
   `flutterfire configure --out=lib/firebase_options_dev.dart` (repeat per flavor).
3. Switch on the flavor in `firebaseOptionsFor()` and return the matching options.
4. Natively: per-flavor `google-services.json` (Android product flavors) and
   `GoogleService-Info.plist` (Xcode schemes/targets).

### Feature flags (Firebase Remote Config)

Feature flags live in Firebase Remote Config and are read through
`RemoteConfigService` (`packages/house_mira_core/lib/config/remote_config_service.dart`).
They are fetched once at startup (`main.dart` calls `initialize()` after
`Firebase.initializeApp`) and cached for the life of the process. Every flag
defaults to `false`, so the app ships with all remote gates off until the
flag is explicitly enabled in the Firebase console. A fetch failure is logged
and the defaults are used: Remote Config never blocks startup.

| Flag | Default | Effect |
| --- | --- | --- |
| `enable_limit_and_paywall` | `false` | Usage limits (reminders/notes) are enforced and the `/paywall` route is reachable. |
| `show_apple_login` | `false` | The "Sign in with Apple" button is rendered on the sign-in (`/account`) and sign-up (`/sign-up`) screens. |

The flag is read at startup and forwarded to the UI as a plain boolean
(`main.dart` → `MyApp.showAppleLogin` → `createRouter` → the views), so
presentation never touches GetIt or Firebase directly.

`show_apple_login` only turns the button **on**: it never reveals it where
the native flow does not exist. The button additionally requires an Apple
platform (`isAppleLoginButtonVisible` in
`packages/house_mira_core/lib/auth/apple_sign_in_handler.dart`), because the
plugin's web flow on Android needs an Apple Services ID plus a redirect
endpoint.

### Key rotation policy

- The publishable key is public by design (RLS protects data), but treat it
  as replaceable: rotate it in the Supabase dashboard
  (Project Settings → API → Rotate key) if it leaks or when rotating on a
  schedule, then update every copy: local `env/*.json` files, GitHub secrets
  (`SUPABASE_URL_PROD`, `SUPABASE_PUBLISHABLE_KEY_PROD`, staging/dev
  equivalents), and rebuild/redeploy all distributed builds.
- Note: a prod publishable key was previously hardcoded in `lib/main.dart`
  and is therefore in git history — rotate it once now that it is removed.
- `service-role` keys stay server-side only (Supabase function secrets /
  dashboard). They must never appear in the repo; the CI secrets check fails
  the build if `service_role` is referenced anywhere under `lib/`.
- CI (`check-no-hardcoded-secrets` job, `tool/check_no_hardcoded_secrets.sh`)
  fails on: `sb_publishable_`/`sb_secret_` literals in Dart source,
  hardcoded `*.supabase.co` URLs in `lib/`, `service_role` references in
  `lib/`, and committed real `env/*.json` files.

### Pull Request Process

1. Create a feature branch from `main`
2. Make your changes
3. Run `fvm flutter analyze` and `fvm flutter test` to ensure code quality
4. Submit a pull request with a clear description

### Automated PR review (Bob)

Every PR gets an automated review: the `call-bob` job of the CI workflow
calls `.github/workflows/opencode-review-bob.yml`, which runs an OpenCode
agent over the pull request diff. The step-by-step pipeline, the grade
semantics and the fail-closed matrix are documented in
[docs/opencode-review-bob.md](docs/opencode-review-bob.md).

- **Pinned, verified CLI.** `tool/install_opencode_cli.sh` downloads the
  pinned npm tarball for the runner's platform and verifies its SHA-512
  (Subresource Integrity) and the binary's SHA-256 before running it. The
  upstream `opencode.ai` installer is deliberately not used: it always
  serves the newest script, so pinning its checksum breaks CI on every
  upstream release.
- **Sandboxed agent.** Project configuration is disabled (a PR cannot
  inject MCP servers, agents or permissions through `opencode.jsonc`), and
  the agent may not run shell commands, edit files, fetch URLs, use skills
  or read outside the checkout. The GitHub token is stripped from the agent
  process; only the workflow itself talks to GitHub.
- **Strict grade gate.** The review must carry a single `GRADE: <A|B|C|D>`
  line in its header (the models answer with a short status line before it)
  and contain a `## Findings` section. Only grade `A` labels the PR
  `automerge`, approves it and merges it. Every lower grade (`B`, `C`, `D`)
  and a missing grade only post the review comment and leave the pull
  request open; the `automerge` label is removed as well, so the
  label-based auto-merge workflow cannot pick the pull request up either.
  Grade lines planted in the diff are stripped before the diff reaches the
  model, and the gate is parsed by `tool/parse_review_grade.py`. That parser
  is taken from the base branch, so a pull request can never change the
  rules it is graded by — a gate change only takes effect for the pull
  requests that follow it.
- **Fail-closed merge gate.** The merge decision lives in
  `tool/review_merge_gate.py` (taken from the base branch, like the grade
  parser) and is covered by unit tests
  (`python3 -m unittest tool.test_review_merge_gate -v`, run in CI):
  `A` merges, `B`/`C`/`D`/a missing grade never do, and every non-`A`
  verdict drops the `automerge` label. The trusted helpers are required:
  when the copy on the base branch cannot be read, the review and the
  auto-merge workflow fail instead of falling back to the copy the pull
  request controls.
- **The grade belongs to the reviewed commit.** The head commit of the
  pull request is captured next to the diff, and the merge gate only
  records the grade when that commit is still the head commit. A pull
  request that received a commit while the review ran is therefore never
  merged on the strength of the grade of the previous commit: the gate
  records nothing, drops the `automerge` label and merges nothing, and
  the re-review of the new commit decides.
- **No stale label can merge a pull request.** Before the review even
  starts, the gate drops a leftover `automerge` label and marks the head
  commit as "review pending"; if the label cannot be dropped, the review
  job fails instead of merging. The verdict is then recorded as a commit
  status (`opencode-review-grade`) on the head commit, and the `Automerge`
  workflow re-checks that status before it merges anything: a pull request
  is only merged while its *current* head commit carries a successful
  `GRADE=A` status. New commits after an `A` grade, a review that never
  finished and a lower grade all keep the pull request open for a human.
  The label-driven merge uses `MERGE_METHOD: squash`, like the review job,
  and the label is dropped again once the merge succeeded. The workflow
  needs `issues: write` for the label, so it can drop it.
- **Fixed model, no credentials.** The review uses a fixed model and does
  not require provider credentials. No provider credential is exposed to
  the review agent, and the model is not overridable — the `model` input
  was removed.
- **Cold-start safe.** On a cold runner the first CLI invocation can start
  before the provider catalog is loaded, and the model then has no route at
  all (`Model unavailable`). The job warms the catalog up first (it lists the
  models until the fixed one shows up) and retries the review when the model
  was not routable, so a cold start cannot silently skip the review.

## APK Distribution

Merging into `main` triggers `.github/workflows/build_apk.yml`:

1. Builds a debug APK (`flutter build apk --debug`)
2. Uploads it to Firebase App Distribution (project `diogoprojects-617e2`) — testers get an email with the install link
3. Uploads the APK as a GitHub Actions artifact, auto-deleted after 3 days (`retention-days: 3`)

You can also trigger it manually via Actions → Build APK → Run workflow.

### Required Secrets

Set these in GitHub repo → Settings → Secrets → Actions:

| Secret | Value |
| --- | --- |
| `FIREBASE_SERVICE_ACCOUNT` | Service account JSON with `Firebase App Distribution Admin` role |
| `FIREBASE_TESTERS` | Comma-separated tester emails |
| `SUPABASE_URL_PROD` | Prod Supabase project URL (injected as `--dart-define=SUPABASE_URL`) |
| `SUPABASE_PUBLISHABLE_KEY_PROD` | Prod Supabase publishable key (injected as `--dart-define=SUPABASE_PUBLISHABLE_KEY`) |

### Firebase Setup (one-time)

1. Firebase console → App Distribution → enable for the Android app
2. Add tester emails
3. Project settings → Service accounts → Generate new private key → store as `FIREBASE_SERVICE_ACCOUNT`

### Android build toolchain (R8)

Release builds are optimized with R8: code shrinking, obfuscation and
**optimized resource shrinking** (Android vitals "DEX code optimization").
Play only reports the optimized pipeline as enabled when the app is built with
Android Gradle Plugin 9.0 or newer — from AGP 9 resource shrinking always runs
inside R8, so resources referenced only from code that R8 removed are dropped
instead of being kept alive by AAPT2 keep rules.

| Component | Version | Why |
| --- | --- | --- |
| Android Gradle Plugin | 9.0.1 | optimized resource shrinking (`android/settings.gradle.kts`) |
| Gradle | 9.1.0 | AGP 9.0 minimum, newest version Flutter 3.41.x supports (`android/gradle/wrapper/gradle-wrapper.properties`) |
| google-services plugin | 4.5.0 | Gradle 9 / AGP 9 compatible |
| Kotlin Gradle plugin | 2.2.20 | unchanged, required by `kotlin-android` |

`android/gradle.properties` keeps `android.newDsl=false` and
`android.builtInKotlin=false`: Flutter 3.41.6's Gradle plugin still reads the
legacy `android {}` DSL and this app applies the `kotlin-android` plugin. Remove
both once Flutter migrates (flutter/flutter#180137); AGP 10 removes the
opt-outs. Neither flag affects optimized resource shrinking.

Two follow-ups when touching R8:

- Anything reached only by name at runtime must be listed in
  `android/app/src/main/res/raw/keep.xml` (e.g. `@drawable/ic_notification`).
- App-level ProGuard keep rules go in `android/app/proguard-rules.pro`. Verify
  a release build's optimization report with
  `unzip -p build/app/outputs/bundle/release/app-release.aab BUNDLE-METADATA/com.android.tools/r8.json`.

## Crashlytics MCP server

Agents can read Crashlytics data (issues, sample stack traces, aggregated
reports) for the Firebase project in `firebase.json`
(`diogoprojects-617e2`) through the official **Firebase MCP server**
(`firebase-tools`). It is wired up in `opencode.jsonc` under
`mcp.servers.firebase` with an explicit tool allow-list, so the server runs
with the repo root as its project directory, picks up `firebase.json`
automatically, and exposes nothing beyond Crashlytics reads.

| MCP tool | What it does |
| --- | --- |
| `crashlytics_get_report` | Aggregated reports: `topIssues`, `topVariants`, `topVersions`, `topOperatingSystems`, `topAndroidDevices`, ... |
| `crashlytics_list_events` | Most recent crash/exception events matching a filter |
| `crashlytics_batch_get_events` | Full sample events (stack traces) by resource name |
| `crashlytics_get_issue` | Issue details and metadata |
| `crashlytics_list_notes` / `crashlytics_create_note` | Notes attached to an issue |
| `crashlytics_update_issue` | Open / close / mute an issue (not enabled by default, see Guardrails) |

### Prerequisites

- Node.js >= 20 — `firebase-tools` runs on Node. The devcontainer image
  installs `nodejs`/`npm` (`.devcontainer/Dockerfile`); on a host machine
  install Node 20+ yourself.
- Firebase CLI credentials (below). Without them every Crashlytics tool
  fails with *"The user is not currently logged into the Firebase CLI"*.
- The **Firebase Crashlytics API** must be enabled on the GCP project
  (`firebasecrashlytics.googleapis.com`). It is `DISABLED` by default on
  this project, and every read then fails with
  *"Firebase Crashlytics API has not been used in project 140355243144
  before or it is disabled"*. Enable it once at
  <https://console.developers.google.com/apis/api/firebasecrashlytics.googleapis.com/overview?project=140355243144>
  (GCP console → project `diogoprojects-617e2` → APIs & Services → Library
  → *Firebase Crashlytics API* → Enable). Enabling it in the Firebase
  console alone is not enough — the GCP API must be on.

### Authentication

The MCP server uses the same credentials as the Firebase CLI. Two options:

**A. Application Default Credentials (service account)** — recommended for
containers and CI:

1. GCP console → project `diogoprojects-617e2` (project number
   `140355243144`) → IAM & Admin → Service Accounts → **Create service
   account**. Name it e.g. `house-mira-crashlytics-reader`.
2. Grant it **Firebase Crashlytics Viewer** (`roles/firebase.crashlytics.viewer`)
   on that project. Nothing else — it is a read-only role. It covers every
   report, issue and event read; `crashlytics_create_note` additionally needs
   `firebasecrashlytics.notes.create` (e.g. `roles/firebase.crashlytics.admin`)
   and answers `403 PERMISSION_DENIED` without it.
3. Create a JSON key and store it **outside the repo**:

   ```bash
   mkdir -p ~/.config/gcloud
   cp <downloaded-key>.json ~/.config/gcloud/firebase-crashlytics-sa.json
   chmod 600 ~/.config/gcloud/firebase-crashlytics-sa.json
   ```

4. **Install it as the ADC file.** `firebase-tools` resolves credentials
   through `google-auth-library`, which looks in this order:
   `GOOGLE_APPLICATION_CREDENTIALS` → `~/.config/gcloud/application_default_credentials.json`
   → `gcloud` user credentials → GCE metadata. The **well-known file** is
   the route that works with the OpenCode MCP server:

   ```bash
   cp ~/.config/gcloud/firebase-crashlytics-sa.json \
      ~/.config/gcloud/application_default_credentials.json
   chmod 600 ~/.config/gcloud/application_default_credentials.json
   ```

   The MCP server re-reads ADC on every call, so this takes effect
   immediately — **no `opencode service restart` and no OpenCode restart**.

   The env var also works, but only when the MCP server process inherits
   it, which means restarting the service:

   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/firebase-crashlytics-sa.json"
   opencode service restart   # the background service must re-read the env
   ```

   `opencode.jsonc` forwards `GOOGLE_APPLICATION_CREDENTIALS` to the MCP
   server process, so no key material ever lands in the repository. Do not
   rely on `opencode service set env GOOGLE_APPLICATION_CREDENTIALS ...` —
   in the devcontainer it answers `Command cancelled` and the value is lost
   on the next restart (`opencode service get` returns `{}`).

   Keep the key out of the working tree. A copy at the repo root is
   ignored by `.gitignore` (`*-sa.json`), but the canonical location is
   `~/.config/gcloud/`.

**B. Firebase CLI login** — for a workstation:

```bash
firebase login --no-localhost   # headless: prints a URL + session id
firebase login <authorizationCode>
```

The signed-in account needs the **Firebase Crashlytics Viewer**
(`roles/firebase.crashlytics.viewer`) role on the project. The login state
lives in `~/.config/configstore/firebase-tools.json`, which is usually empty
in a fresh container — prefer option A there. Without credentials every
Crashlytics tool fails with *"The user is not currently logged into the
Firebase CLI"*.

### Active project

`firebase_get_project` and `firebase_list_apps` need an **active project**,
which is a separate thing from the credentials. `firebase_update_environment`
is not in the tool allow-list, so the active project is pinned by
`.firebaserc` in the repo root (safe to commit, contains no secrets):

```json
{
  "projects": {
    "default": "diogoprojects-617e2"
  }
}
```

Without it those two tools fail with *"PRECONDITION_FAILED: To proceed
requires an active project"*. The Crashlytics tools do not need it.

### App IDs

Every Crashlytics tool takes the Firebase **app id**, not the project id.

| Platform | App ID |
| --- | --- |
| Android | `1:140355243144:android:a6ac1f14183172f272633d` |
| iOS | `1:140355243144:ios:08ceded889bb563c72633d` |

The iOS app is registered in Firebase but has no Crashlytics data yet, so
iOS report calls answer `404 Requested entity was not found`. That is a
data gap, not an auth failure — do not go chasing credentials when it
happens.

### Verify

```bash
opencode mcp list   # firebase: connected
ls -l ~/.config/gcloud/application_default_credentials.json
```

`connected` only means the MCP process started — it says nothing about
credentials. To prove the credentials work, call a Crashlytics tool
(`crashlytics_get_report` with `report: "topIssues"`) and check that it
returns issues instead of *"The user is not currently logged into the
Firebase CLI"*.

### Asking an agent to review crashes

The MCP server is already wired up in `opencode.jsonc`, so an agent can pull
live crash data with a plain-language request. Canonical prompts:

| Prompt | What the agent does |
| --- | --- |
| *"Review the Firebase Crashes"* | Full triage: fetch, diagnose, fix, verify |
| *"What are the top crashing issues in the Android app?"* | Report only, no code changes |
| *"Fetch the stack trace of issue `<issueId>`"* | `crashlytics_batch_get_events` with the issue's `sampleEvent` |
| *"Which app version crashes the most?"* | `crashlytics_get_report` with `report: "topVersions"` |
| *"Which devices crash the most?"* | `crashlytics_get_report` with `report: "topAndroidDevices"` |
| *"Add a note to issue `<issueId>` saying the fix landed in `<version>`"* | `crashlytics_create_note` (needs a write role — see [Authentication](#authentication)) |

The whole workflow is packaged as a skill, so asking for a crash review
picks it up automatically:

```
.agents/skills/firebase-crashlytics/
├── SKILL.md                 # preflight, triage workflow, guardrails
└── references/triage.md     # report fields, crash classes seen so far
```

Ask for it explicitly with `@firebase-crashlytics` if you want the agent to
start from the checklist rather than from the prompt. The triage recipe
behind *"Review the Firebase Crashes"*:

1. `crashlytics_get_report` with `report: "topIssues"`. Pass
   `filter.intervalStartTime` / `filter.intervalEndTime` for a specific
   window; the default is the last 7 days.
2. For every issue worth fixing, `crashlytics_batch_get_events` with the
   issue's `sampleEvent` resource name to get the real stack trace — the
   issue `subtitle` is only a one-line summary and often not enough.
3. Map the stack frame to the repo and fix the root cause. The crash
   report gives the Dart file, e.g.
   `package:house_mira_reminders/application/reminder_notification_service.dart`.
4. Verify with the order in `AGENTS.md` (`fvm flutter analyze` →
   `fvm flutter test`).
5. Optionally `crashlytics_create_note` on the issue recording what changed
   and in which release.

Check the issue's `lastSeenVersion` against `pubspec.yaml` before touching
code: an issue that only affects versions older than the current one is
**stale** (the fix already shipped) and needs a note, not a rewrite.

Notes that keep the loop cheap:

- `crashlytics_list_events` requires `filter.issueId` or
  `filter.issueVariantId` — it cannot list free-form events.
- `crashlytics_get_report` reports the aggregate; the stack trace lives in
  `crashlytics_batch_get_events`.
- `crashlytics_update_issue` (close/mute a fixed issue) is **not** exposed.
  Only `crashlytics_create_note` can record that a fix shipped.

### Guardrails

The server is started with an explicit `--tools` allow-list, so the agent can
only ever see these ten tools:

```
crashlytics_get_report, crashlytics_list_events, crashlytics_batch_get_events,
crashlytics_get_issue, crashlytics_list_notes, crashlytics_create_note,
firebase_read_resources, firebase_get_environment, firebase_get_project,
firebase_list_apps
```

Everything that touches Firebase infrastructure (`firebase_deploy`,
`firebase_init`, `firebase_create_*`, `firebase_update_environment`) and the
Crashlytics mutations `crashlytics_update_issue` /
`crashlytics_delete_note` are not exposed at all. A second layer in
`opencode.jsonc` (`permissions`) denies the same tools plus the interactive
auth tools (`firebase_login`, `firebase_logout`).

To let the agent close fixed crashes, add `crashlytics_update_issue` to the
`--tools` list and drop the matching `permissions` entry.

### REST API fallback

The MCP server is a thin wrapper over the Crashlytics REST API
(`https://firebasecrashlytics.googleapis.com/v1alpha`), which can be called
directly from CI or a script:

```bash
TOKEN=$(gcloud auth print-access-token)   # or a service-account access token
APP_ID="1:140355243144:android:a6ac1f14183172f272633d"
curl -sS -H "Authorization: Bearer $TOKEN" \
  "https://firebasecrashlytics.googleapis.com/v1alpha/projects/140355243144/apps/$APP_ID/reports/topIssues?page_size=10"
```

Paths (the project segment is the project **number**, not the project id):

| Path | Methods |
| --- | --- |
| `/projects/{projectNumber}/apps/{appId}/reports/{reportName}` | GET |
| `/projects/{projectNumber}/apps/{appId}/events` | GET |
| `/projects/{projectNumber}/apps/{appId}/events:batchGet?names=...` | GET |
| `/projects/{projectNumber}/apps/{appId}/issues/{issueId}` | GET, PATCH (`?updateMask=state`) |
| `/projects/{projectNumber}/apps/{appId}/issues/{issueId}/notes` | GET, POST |
| `/projects/{projectNumber}/apps/{appId}/issues/{issueId}/notes/{noteId}` | DELETE |

## Sign in with Apple

Native Apple ID authentication (`sign_in_with_apple`) next to the Google
Sign-In button, on the sign-in screen (`/account`) and the sign-up screen
(`/sign-up`).

Client code:

| Piece | Where |
| --- | --- |
| Handler (plugin bridge, nonce, error mapping) | `packages/house_mira_core/lib/auth/apple_sign_in_handler.dart` |
| Token exchange + session creation | `AuthService.signInWithApple` (`packages/house_mira_core/lib/auth/auth_service.dart`) |
| DI wiring | `lib/core/injections/service_locator.dart` |
| UI | `packages/house_mira_account/.../account_no_account_auth_widget.dart`, `packages/house_mira_login/.../sign_up_screen.dart` |

How the flow works:

1. The handler generates a raw nonce per attempt and sends its SHA-256
   hash to Apple (embedded in the `nonce` claim of the identity token).
2. The identity token is exchanged with Supabase via
   `auth.signInWithIdToken(provider: OAuthProvider.apple, idToken: …,
   nonce: <raw nonce>)`. Supabase hashes the raw nonce again and compares
   it with the claim, which rejects replayed tokens.
3. Apple's identity token never carries the user's name: Apple only
   returns it on the **first** authorization. The handler exposes it and
   the service stores it in the user metadata and the `profiles` row
   (best-effort, never fails the sign-in).

The **Continue with Apple** button is opt-in: it is only rendered when the
Remote Config flag `show_apple_login` is enabled (default `false`, see
[Feature flags](#feature-flags-firebase-remote-config)) **and** the platform
supports the native flow (`isAppleSignInSupported`): the plugin's web flow on
Android needs an Apple Services ID plus a redirect endpoint, so the button is
hidden instead of leading to a dead end.

One-time setup (not part of the repo):

| Where | What |
| --- | --- |
| Apple Developer portal | Enable the **Sign in with Apple** capability on the App ID `com.housemira.app` (and regenerate the provisioning profile). |
| Xcode | The capability is declared in `ios/Runner/Runner.entitlements` (`com.apple.developer.applesignin`) and in the Runner target capabilities. |
| Supabase dashboard → Authentication → Providers → Apple | Enable the provider and add `com.housemira.app` to **Client IDs** (the audience of the native identity token). A native-only setup needs no Services ID and no client secret. |

## Supabase Edge Functions

Deployed on the linked project (`VitaFolderMobileBackend`).
Source: `supabase/functions/<name>/index.ts` (Deno).

| Function | Method | Auth | What it does |
| --- | --- | --- | --- |
| `delete-account` | `POST /functions/v1/delete-account` | Caller JWT (`Authorization: Bearer <token>`) | Deletes the caller's auth user via `auth.admin.deleteUser`. Postgres `ON DELETE CASCADE` then removes `profiles`, `family_memberships`, `notification_tokens` and `notification_logs` rows. The `families` row is left intact (`created_by` SET NULL) so other members keep their data. Blocked when the caller is the sole remaining member of an owned family — nothing is deleted. |
| `join-family-v1` | `POST /functions/v1/join-family-v1` | Caller JWT (`Authorization: Bearer <token>`, caller must be `owner`/`admin` of the target family) **or** trusted-backend shared secret (`x-join-secret` header, server-to-server only) | Adds an existing account (by email) to a family (by family code) as `member`. Body: `{ email, familyCode }` (code canonicalized like the app: `ab-1234` → `AB1234`). Idempotent: already-a-member returns success. Returns `{ success: true, family_id }` on success. |
| `resend-email-v1` | `POST /functions/v1/resend-email-v1` | Caller JWT (enforced by `withSupabase({ auth: "user" })`) | Sends the HouseMira family-invite email via the Resend API (`from: HouseMira <contact@contact.housemira.com>`). Body: `{ to, locale?, inviterName?, familyName?, inviteCode?, familyCode? }` (`inviteCode` still accepted for older clients; the link uses `familyCode`). Subject and HTML are rendered server-side (EN/PT, English fallback). CTA: `https://housemira.com/join-family?code=<familyCode>&email=<to>` (bare `/join-family` when no code; opens the website join page, which bridges into the app and pre-fills the form from `email`). Returns `{ success: true, id }` on success. |

### `delete-account` details

- UID is taken from the verified JWT server-side, never from the request body.
- Sole-owner guard: for each family where the caller has `role = 'owner'` in `family_memberships`, counts members; if any family has ≤ 1 member, aborts.
- CORS preflight (`OPTIONS`) returns `ok`.

Responses:

| Status | Body | Meaning |
| --- | --- | --- |
| 200 | `{ "success": true }` | User deleted |
| 401 | `{ "code": "unauthorized" }` | Missing/invalid JWT |
| 405 | `{ "code": "method_not_allowed" }` | Not `POST` |
| 409 | `{ "code": "sole_owner", "family_id": "<uuid>" }` | Caller is sole remaining member of an owned family; client should point at Family Settings |
| 500 | `{ "code": "lookup_failed" }` / `{ "code": "delete_failed" }` | Membership lookup or `admin.deleteUser` failed |

Required function secrets:

| Secret | Purpose |
| --- | --- |
| `SUPABASE_URL` | Project URL (JWT verification + admin client) |
| `SUPABASE_ANON_KEY` | Verifies the caller JWT |
| `SUPABASE_SERVICE_ROLE_KEY` | Membership checks + `auth.admin.deleteUser` |

### `join-family-v1` details

- Source: `supabase/functions/join-family-v1/index.ts` (Deno). Mirrors the client-side join (`PeopleRepositoryImpl.joinFamily`): canonicalize the code (`[A-Z0-9]{6}`, separators/casing ignored), resolve the family by `invite_code`, idempotently insert the `family_memberships` row as `member`, then best-effort insert the `people` row (never fails the join).
- UID is taken from the verified JWT server-side, never from the request body. The caller must hold role `owner` or `admin` on the target family — RLS is bypassed via the service-role client (the membership INSERT policy only permits self-insert), so this check is the security boundary.
- Trusted-backend mode: a call carrying a valid `x-join-secret` header skips the owner/admin check (the secret itself is the authorization). The secret lives ONLY in the website backend env — never browser JS, the app, or any client. Compared in constant time (SHA-256 + byte-wise diff accumulation); present-but-wrong returns `403` without JWT fallthrough. The public anon key is never accepted as authorization.
- The target email must belong to a registered account with a `profiles` row; otherwise `unknown_user` (the account must finish signup first). Note: distinct `family_not_found` / `unknown_user` codes let an owner/admin caller probe registered emails — accepted trade-off for usable errors.
- CORS preflight (`OPTIONS`) returns `ok`; only `POST` is accepted.

Responses:

| Status | Body | Meaning |
| --- | --- | --- |
| 200 | `{ "success": true, "family_id": "<uuid>" }` (+ `"already_member": true` when already joined) | Member added (idempotent) |
| 400 | `{ "code": "invalid_payload" }` / `{ "code": "invalid_json" }` | Bad email/code shape or body |
| 401 | `{ "code": "unauthorized" }` | Missing/invalid JWT |
| 403 | `{ "code": "not_authorized" }` | Caller is not owner/admin of the family (or wrong join secret) |
| 404 | `{ "code": "family_not_found" }` | No family for the code |
| 404 | `{ "code": "unknown_user" }` | No fully-registered account for the email |
| 405 | `{ "code": "method_not_allowed" }` | Not `POST` |
| 500 | `{ "code": "missing_secret" }` | Supabase secret not set |
| 500 | `{ "code": "lookup_failed" }` / `{ "code": "membership_failed" }` | Family/role/user lookup or membership insert failed |
| 500 | `{ "code": "internal" }` | Unhandled error (logged server-side; never a bare Internal Server Error) |

Required function secrets:

| Secret | Purpose |
| --- | --- |
| `SUPABASE_URL` | Project URL (JWT verification + admin client) |
| `SUPABASE_ANON_KEY` | Verifies the caller JWT |
| `SUPABASE_SERVICE_ROLE_KEY` | User lookup + membership/people writes (bypasses RLS; never leaves the server) |
| `JOIN_FAMILY_SHARED_SECRET` | Trusted-backend mode only: authorizes `x-join-secret` callers (website backend env only; unset disables the header path) |

### Deploy & local dev

```bash
# One-time: link to the project
supabase link --project-ref <project-ref>

# Set secrets (dashboard: Project Settings → Edge Functions also works)
supabase secrets set SUPABASE_URL=<url> SUPABASE_ANON_KEY=<key> SUPABASE_SERVICE_ROLE_KEY=<key> RESEND_API_KEY=<key> JOIN_FAMILY_SHARED_SECRET=<random-secret>

# Deploy
supabase functions deploy delete-account
supabase functions deploy join-family-v1
supabase functions deploy resend-email-v1

# Serve locally
supabase functions serve delete-account
supabase functions serve join-family-v1
supabase functions serve resend-email-v1
```

### Client usage

`lib/core/auth/auth_service.dart` → `AuthService.deleteAccount()`:

```dart
await _client.functions.invoke('delete-account', method: HttpMethod.post);
```

Maps `409 sole_owner` → `SoleOwnerException(familyId)`, `401` → `AuthException('Not signed in.')`, other failures → `DeleteAccountException`. Covered in `test/core/auth/auth_service_test.dart`.

### `resend-email-v1` details

- Source: `supabase/functions/resend-email-v1/index.ts` (Deno).
- Auth is enforced by `withSupabase({ auth: "user" })` — no valid caller JWT, no handler run.
- Validates `to` (email shape); optional `locale` (`en`/`pt`, prefix-matched so `pt-BR` → `pt`, English fallback), `inviterName`, `familyName`, `inviteCode` (legacy, still accepted), `familyCode` (feeds the join-family CTA; must be strings when present). CORS preflight (`OPTIONS`) returns `ok`; only `POST` is accepted.
- Renders subject + HTML server-side in the request locale using the app sand palette (`#FAF8F5` bg, `#634F39` headings, `#C2B299` CTA). CTA: `https://housemira.com/join-family?code=<familyCode>&email=<to>` (bare `/join-family` when no code; opens the website join page, `email` pre-fills its form).

Responses:

| Status | Body | Meaning |
| --- | --- | --- |
| 200 | `{ "success": true, "id": "<resend-id>" }` | Email accepted by Resend |
| 400 | `{ "code": "invalid_payload" }` / `{ "code": "invalid_json" }` | Bad request body |
| 405 | `{ "code": "method_not_allowed" }` | Not `POST` |
| 500 | `{ "code": "missing_secret" }` | `RESEND_API_KEY` secret not set |
| 502 | `{ "code": "resend_failed", "detail": <resend-body> }` | Resend API call failed or rejected the request |

Required function secrets:

| Secret | Purpose |
| --- | --- |
| `RESEND_API_KEY` | Authenticates against the Resend API |

### Client usage (`resend-email-v1`)

`lib/core/functions/edget_functions.dart` → `EdgetFunctions.sendEmail()`:

```dart
await _client.functions.invoke('resend-email-v1', body: {
  'to': to,
  'locale': locale, // 'en'/'pt'
  'inviterName': inviterName, // optional
  'familyName': familyName, // optional
  'inviteCode': inviteCode, // optional, legacy (accepted, unused in link)
  'familyCode': familyCode, // optional, appended to the join-family URL
});
```

Called from `InvitePeopleScreen` via `InvitePeopleCubit.sendInvite()`: locale comes from `Localizations.localeOf(context).languageCode`, inviter name from `AuthService.getProfileName()` (falls back to the email prefix), family name + codes travel via the `/invite-people` route extra from `PeopleLoadedWidget` (the family code is the family's own code and is forwarded as both `inviteCode` and `familyCode`).

Returns `true` only when the function responds with `{ success: true }`. Covered in `test/core/functions/edget_functions_test.dart`.

## References

https://supabase.com/docs/guides/getting-started/quickstarts/flutter