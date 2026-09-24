# HouseMira — Agent Guidelines

Family management app. Flutter 3.41.6 via FVM, Supabase backend,
flutter_bloc Cubits, GetIt DI, go_router. Keep it clean, small, and tested.

References: [architecture](.agents/references/architecture.md) ·
[cubit](.agents/references/cubit.md) · [testing](.agents/references/testing.md) ·
[supabase](.agents/references/supabase.md)

## Commands (always use fvm, never bare flutter or dart)

Setup command:

```bash
fvm flutter pub get
```

Lint command (must be clean: 0 errors, 0 warnings) — run
`fvm flutter analyze` before pushing:

```bash
fvm flutter analyze
```

Test command (or pass a scope such as test/features/account) — run
`fvm flutter test` for the full suite:

```bash
fvm flutter test
```

Coverage command (run before touching business-logic layers):

```bash
fvm flutter test --coverage
```

CI is defined in `.github/workflows/ci.yml` and runs dart analyze
with fatal warnings, flutter analyze with fatal warnings (infos allowed),
tests with coverage, and enforces 100 percent per-file coverage for
business-logic layers (see below). The lint set is very_good_analysis
with public_member_api_docs off — fix lints, do not add ignore comments.

## Code rules

- Feature-first layers under lib/features/<feature>/ with domain, data,
  application, and presentation subfolders; shared code in `lib/core/`.
  Concrete examples: `lib/features/reminders/domain`,
  `lib/features/reminders/application`, `lib/features/people/data`,
  `lib/features/people/presentation`.
  Details: [architecture](.agents/references/architecture.md).
- State: one Cubit per concern, sealed states, Loading first then exactly
  one outcome state, services injected, no Supabase imports in cubits.
  Details: [cubit](.agents/references/cubit.md).
- Repositories return Either of Failure or success; entities are immutable
  with copyWith and a from constructor that returns null on bad input.
- Displayed text via AppLocalizations backed by `lib/l10n/app_en.arb`
  (and `lib/l10n/app_pt.arb`) — never hardcode user-visible strings.
- Naming: suffix View, Widget, Cubit, State, Usecase, Entity, Repository,
  Service, ServiceLocator; files are snake_case.
- Async: await inside async functions; sync callbacks either become async
  with await or use unawaited for fire-and-forget. Catch with on Object
  catch (never a bare catch, never narrow silently).

## Error handling — never fake data

- Never fall back to defaults on parse/validation failure: return null.
  No silent current-time fallback, empty-string fallback, or placeholders.
  Explicit failure beats wrong data.

## Environments & secrets

- No backend credentials in `lib/`: Supabase URL/key arrive via
  dart-define flags (APP_FLAVOR, SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY)
  through AppConfig.fromEnvironment in `lib/core/config/app_config.dart`.
  Startup throws StateError on missing/invalid values — never add fallbacks.
- Local: copy an example file from `env/` (e.g.
  `env/dev.example.json`) to a sibling env JSON file, fill in, then run:

```bash
fvm flutter run --dart-define-from-file=env/dev.json
```

  Real env JSON files are gitignored and CI rejects them if committed.
- Firebase: one project today; firebaseOptionsFor in
  `lib/core/config/firebase_options_provider.dart` is the per-flavor seam
  (provisioning steps in README "Environments & secrets").
- CI check-no-hardcoded-secrets (`tool/check_no_hardcoded_secrets.sh`)
  fails on publishable/secret key literals, hardcoded Supabase project URLs
  in `lib/`, or service_role references in `lib/`. Keep `test/` fakes on
  reserved example hosts with mock anon keys (see test/widget_test.dart).

## Testing

New code ships with tests: cubit state sequences (including cancel and
failure paths), unit tests for use-case and entity branches (coverage
gate), widget tests for button wiring. Throwaway repro tests go in the
system temp directory outside the repo, not in `test/`.
Test runner and coverage gate details live in
`.github/workflows/ci.yml` and `test/`.
Details: [testing](.agents/references/testing.md).

## Supabase & git

- Backend and edge functions: see [supabase](.agents/references/supabase.md);
  function source lives in `supabase/functions/delete-account`,
  `supabase/functions/resend-email-v1`, and its docs
  live in `README.md`. Auth flows live in
  `lib/core/auth/auth_service.dart` and DI is wired in
  `lib/core/injections/service_locator.dart`.
- Supabase project: VitaFolderMobileBackend, project ref
  jheqalwrnztavzxjsdcj, region West EU (Ireland). Link with
  supabase link --project-ref jheqalwrnztavzxjsdcj, then deploy with
  supabase functions deploy <name> (e.g. resend-email-v1).
  Required function secret RESEND_API_KEY is already set on the project.
- Never expose service-role keys. Commit, push, or open a PR only when
  explicitly asked.
