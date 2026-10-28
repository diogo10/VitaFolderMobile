# HouseMira — Agent Guidelines

Family management app. Flutter 3.47.8 via FVM, Supabase backend,
flutter_bloc Cubits, GetIt DI, go_router. Keep it clean, small, and tested.

References: [architecture](.agents/references/architecture.md) ·
[cubit](.agents/references/cubit.md) · [testing](.agents/references/testing.md) ·
[supabase](.agents/references/supabase.md) · [fonts](.agents/references/fonts.md)

## Commands (always use fvm, never bare flutter or dart)

Quick reference (run from repo root):

- Setup: `fvm flutter pub get`
- Lint command: `fvm flutter analyze`
- Test command: `fvm flutter test`
- Coverage: `fvm flutter test --coverage`

### Setup

```bash
fvm flutter pub get
```

### Lint

Lint command. Must be clean: 0 errors, 0 warnings. Run before pushing:

```bash
fvm flutter analyze
```

### Test

Test command. Full workspace suite, or a selective scope per team:

```bash
fvm flutter test
melos test:people # selective: test:<core|people|reminders|notes|home|account|paywall|onboarding|login>
```

### Coverage

Run before touching business-logic layers:

```bash
melos test # per-package coverage, then:
python3 tool/check_business_logic_coverage.py
```

## Verification

After a change, run in order and expect:

1. `fvm flutter analyze` → `No issues found!`
2. `fvm flutter test` → `All tests passed!`
3. `melos test` (business-logic change only) →
   `python3 tool/check_business_logic_coverage.py` reports 100% per file
   under each package's domain/ and application/ layers.
4. `python3 tool/check_feature_boundaries.py` → `Package boundaries hold`
   (no cross-package data/ imports, core never imports features).

CI (`.github/workflows/ci.yml`) runs the same steps with bare flutter/dart
because the runner pre-installs Flutter — locally always use the fvm
commands above, never bare flutter or dart:

```bash
dart analyze --fatal-warnings
flutter analyze --no-fatal-infos --fatal-warnings
flutter test --coverage
python3 tool/check_layer_boundaries.py
python3 tool/check_feature_boundaries.py
python3 tool/check_business_logic_coverage.py
```

The lint set is very_good_analysis with public_member_api_docs off —
fix lints, do not add ignore comments.

## Code rules

- Feature-first packages under packages/house_mira_<feature>/lib/ with
  domain, data, application, and presentation subfolders; shared code in
  `packages/house_mira_core/lib/`; app composition root only in `lib/`
  (main.dart, core/router/*, core/injections/service_locator.dart).
  Concrete examples: `packages/house_mira_reminders/lib/domain`,
  `packages/house_mira_reminders/lib/application`,
  `packages/house_mira_people/lib/data`,
  `packages/house_mira_people/lib/presentation`.
  Each package exposes its public API via its lib/house_mira_<feature>.dart
  file (domain only, e.g. `packages/house_mira_reminders/lib/house_mira_reminders.dart`)
  and its DI graph via its lib/*_service_locator.dart file
  (e.g. `packages/house_mira_reminders/lib/reminder_service_locator.dart`).
  Import rules P1–P6 (`tool/check_feature_boundaries.py`): no
  cross-package data/ imports, core never imports features,
  feature-to-feature via domain/ only.
  Details: [architecture](.agents/references/architecture.md).
- State: one Cubit per concern, sealed states, Loading first then exactly
  one outcome state, services injected, no Supabase imports in cubits.
  Details: [cubit](.agents/references/cubit.md).
- Repositories return Either of Failure or success; entities are immutable
  with copyWith and a from constructor that returns null on bad input.
- Displayed text via AppLocalizations backed by
  `packages/house_mira_core/lib/l10n/app_en.arb`
  (and `packages/house_mira_core/lib/l10n/app_pt.arb`) — never hardcode user-visible strings.
- Naming: suffix View, Widget, Cubit, State, Usecase, Entity, Repository,
  Service, ServiceLocator; files are snake_case.
- Async: await inside async functions; sync callbacks either become async
  with await or use unawaited for fire-and-forget. Catch with on Object
  catch (never a bare catch, never narrow silently).
- Fonts ship in the bundle (never reintroduce a runtime font fetch) and Android
  notification icons use bare drawable names.
  See [fonts](.agents/references/fonts.md).

## Error handling — never fake data

- Never fall back to defaults on parse/validation failure: return null.
  No silent current-time fallback, empty-string fallback, or placeholders.
  Explicit failure beats wrong data.

## Environments & secrets

- No backend credentials in `lib/` or any package lib/ directory (e.g. `packages/house_mira_core/lib/`): Supabase URL/key arrive via
  dart-define flags (APP_FLAVOR, SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY)
  through AppConfig.fromEnvironment in `packages/house_mira_core/lib/config/app_config.dart`.
  Startup throws StateError on missing/invalid values — never add fallbacks.
- Local: copy an example file from `env/` (e.g.
  `env/dev.example.json`) to a sibling env JSON file, fill in, then run:

```bash
fvm flutter run --dart-define-from-file=env/dev.json
```

  Real env JSON files are gitignored and CI rejects them if committed.
- Firebase: one project today; firebaseOptionsFor in
  `packages/house_mira_core/lib/config/firebase_options_provider.dart` is the per-flavor seam
  (provisioning steps in README "Environments & secrets").
- CI check-no-hardcoded-secrets (`tool/check_no_hardcoded_secrets.sh`)
  fails on publishable/secret key literals, hardcoded Supabase project URLs
  in `lib/` or any package lib/ directory (e.g. `packages/house_mira_core/lib/`), or service_role references in `lib/` or `packages/`. Keep `test/` fakes on
  reserved example hosts with mock anon keys (see test/widget_test.dart).

## Testing

New code ships with tests: cubit state sequences (including cancel and
failure paths), unit tests for use-case and entity branches (coverage
gate), widget tests for button wiring. Feature tests live in
each package test/ directory (e.g. `packages/house_mira_reminders/test/`), core tests in
`packages/house_mira_core/test/`; app-shell tests (router, critical
paths, goldens) stay in `test/`. Throwaway repro tests go in the
system temp directory outside the repo, not in `test/`.
Test runner and coverage gate details live in
`.github/workflows/ci.yml` and `test/`.
Details: [testing](.agents/references/testing.md).

## Supabase & git

- Backend and edge functions: see [supabase](.agents/references/supabase.md);
  function source lives in `supabase/functions/delete-account`,
  `supabase/functions/resend-email-v1`, and its docs
  live in `README.md`. Auth flows live in
  `packages/house_mira_core/lib/auth/auth_service.dart` and per-feature DI
  is wired in each package's lib/*_service_locator.dart file (e.g. `packages/house_mira_reminders/lib/reminder_service_locator.dart`), aggregated in
  `lib/core/injections/service_locator.dart`.
- Supabase project: VitaFolderMobileBackend, project ref
  jheqalwrnztavzxjsdcj, region West EU (Ireland). Link with
  supabase link --project-ref jheqalwrnztavzxjsdcj, then deploy with
  supabase functions deploy <name> (e.g. resend-email-v1).
  Required function secret RESEND_API_KEY is already set on the project.
- Crashlytics: the `firebase` MCP server (opencode.jsonc -> mcp.servers.firebase)
  exposes the Crashlytics tool group for project diogoprojects-617e2
  (Android app id 1:140355243144:android:a6ac1f14183172f272633d, iOS
  1:140355243144:ios:08ceded889bb563c72633d). Use
  crashlytics_get_report / crashlytics_list_events /
  crashlytics_batch_get_events to triage real crashes. The server runs with a
  `--tools` allow-list, so deploy/mutation tools (and crashlytics_update_issue)
  are not exposed. Setup and auth: README "Crashlytics MCP server".
  Credentials: ADC service account at
  ~/.config/gcloud/application_default_credentials.json (copy it there
  from the downloaded key; the MCP server re-reads it per call, no restart
  needed). Active project comes from .firebaserc. If a tool answers
  "The user is not currently logged into the Firebase CLI" the ADC file is
  missing; if it answers "PRECONDITION_FAILED ... requires an active
  project" .firebaserc is missing. The service account holds the read-only
  roles/firebase.crashlytics.viewer, so crashlytics_create_note answers
  "403 PERMISSION_DENIED" - print the note text for the user instead.
- Crash review workflow: on a request like "Review the Firebase Crashes",
  load the `firebase-crashlytics` skill (.agents/skills/firebase-crashlytics/)
  and follow it: fetch topIssues via crashlytics_get_report, pull each
  issue's sampleEvent stack trace with crashlytics_batch_get_events, map the
  stack frame to the repo, fix the root cause, then verify per the order
  above. Check the issue's lastSeenVersion against pubspec.yaml first: an
  issue that only affects older builds is stale and needs a note, not a
  code change. iOS report calls 404 today (no data yet) - not an auth
  problem.
- Never expose service-role keys. Commit, push, or open a PR only when
  explicitly asked.
