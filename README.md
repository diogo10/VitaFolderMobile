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

## References

https://supabase.com/docs/guides/getting-started/quickstarts/flutter