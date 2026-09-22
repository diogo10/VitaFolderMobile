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

## Supabase Edge Functions

Deployed on the linked project (`VitaFolderMobileBackend`).
Source: `supabase/functions/<name>/index.ts` (Deno).

| Function | Method | Auth | What it does |
| --- | --- | --- | --- |
| `delete-account` | `POST /functions/v1/delete-account` | Caller JWT (`Authorization: Bearer <token>`) | Deletes the caller's auth user via `auth.admin.deleteUser`. Postgres `ON DELETE CASCADE` then removes `profiles`, `family_memberships`, `notification_tokens` and `notification_logs` rows. The `families` row is left intact (`created_by` SET NULL) so other members keep their data. Blocked when the caller is the sole remaining member of an owned family — nothing is deleted. |

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

### Deploy & local dev

```bash
# One-time: link to the project
supabase link --project-ref <project-ref>

# Set secrets (dashboard: Project Settings → Edge Functions also works)
supabase secrets set SUPABASE_URL=<url> SUPABASE_ANON_KEY=<key> SUPABASE_SERVICE_ROLE_KEY=<key>

# Deploy
supabase functions deploy delete-account

# Serve locally
supabase functions serve delete-account
```

### Client usage

`lib/core/auth/auth_service.dart` → `AuthService.deleteAccount()`:

```dart
await _client.functions.invoke('delete-account', method: HttpMethod.post);
```

Maps `409 sole_owner` → `SoleOwnerException(familyId)`, `401` → `AuthException('Not signed in.')`, other failures → `DeleteAccountException`. Covered in `test/core/auth/auth_service_test.dart`.

## References

https://supabase.com/docs/guides/getting-started/quickstarts/flutter