# HouseMira — Agent Guidelines

Family management app. Flutter 3.41.6 via FVM, Supabase backend,
flutter_bloc Cubits, GetIt DI, go_router. Keep it clean, small, and tested.

References: [architecture](.agents/references/architecture.md) ·
[cubit](.agents/references/cubit.md) · [testing](.agents/references/testing.md) ·
[supabase](.agents/references/supabase.md)

## Commands (always `fvm`, never bare `flutter`/`dart`)

```bash
fvm flutter pub get
fvm flutter analyze          # must be clean: 0 errors, 0 warnings
fvm flutter test             # or test/<path> for a scope
fvm flutter test --coverage  # before touching domain/ or application/
```

CI (`ci.yml`) runs `dart analyze --fatal-warnings`,
`flutter analyze --no-fatal-infos --fatal-warnings`, tests with coverage,
and enforces **100% per-file coverage** under `lib/**/domain/` and
`lib/**/application/`. Strict `very_good_analysis` set
(`public_member_api_docs` off) — fix lints, don't add `// ignore:`.

## Code rules

- Feature-first layers (`application/`, `domain/`, `data/`, `presentation/`);
  shared code in `lib/core/`. Details: [architecture](.agents/references/architecture.md).
- State: one Cubit per concern, sealed states, `Loading` → outcome,
  services injected, no Supabase imports in cubits. Details: [cubit](.agents/references/cubit.md).
- Repositories return `Either<Failure, T>`; entities immutable with
  `copyWith`/`from` (returns `null` on bad input).
- Displayed text via `AppLocalizations` (`lib/l10n/*.arb`) — never hardcode.
- Name things: `*View`, `*Widget`, `*Cubit`, `*State`, `*Usecase`,
  `*Entity`, `*Repository`, `*Service`, `*ServiceLocator`; files `snake_case`.
- Async: `await` in async fns; sync callbacks go `async`+`await` or
  `unawaited()` for fire-and-forget. Catches: `on Object catch` (never bare
  `catch`, never narrow silently).

## Error handling — never fake data

- **Never fall back to defaults** on parse/validation failure: return `null`.
  No silent `DateTime.now()`, `''`, or placeholders. Explicit failure beats
  wrong data.

## Environments & secrets

- No backend credentials in `lib/`: Supabase URL/key arrive via
  `--dart-define` (`APP_FLAVOR`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`)
  through `AppConfig.fromEnvironment()` (`lib/core/config/`). Startup throws
  `StateError` on missing/invalid values — never add fallbacks.
- Local: `cp env/<flavor>.example.json env/<flavor>.json`, fill in, run with
  `fvm flutter run --dart-define-from-file=env/<flavor>.json`. Real
  `env/*.json` files are gitignored and CI rejects them if committed.
- Firebase: one project today; `firebaseOptionsFor()` is the per-flavor seam
  (provisioning steps in README "Environments & secrets").
- CI `check-no-hardcoded-secrets` (`tool/check_no_hardcoded_secrets.sh`)
  fails on `sb_publishable_`/`sb_secret_` literals, hardcoded
  `*.supabase.co` URLs in `lib/`, or `service_role` references in `lib/`.
  Keep `test/` fakes on `mock.supabase.co` / `mock-anon-key`.

## Testing

New code ships with tests: cubit state sequences (incl. cancel + failure),
unit tests for use-case/entity branches (coverage gate), widget tests for
button wiring. Throwaway repro tests go in `/tmp`, not `test/`. Details:
[testing](.agents/references/testing.md).

## Supabase & git

Backend + edge functions: [supabase](.agents/references/supabase.md);
function docs live in `README.md`. Never expose service-role keys.
Commit/push/PR only when explicitly asked.
