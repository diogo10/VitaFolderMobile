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