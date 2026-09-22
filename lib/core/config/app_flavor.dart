/// Backend environments supported by the app.
///
/// Each flavor maps to a **separate Supabase project** (dev/staging/prod)
/// so test data and production data never mix. The flavor is supplied at
/// build/run time via `--dart-define=APP_FLAVOR=<name>` (or an env file,
/// see `env/*.example.json`).
enum AppFlavor {
  /// Local development backend.
  dev,

  /// Pre-release backend mirroring production.
  staging,

  /// Production backend used by store builds.
  prod,
}

/// Parses a `--dart-define=APP_FLAVOR` value.
///
/// Returns `null` for unknown or empty input instead of guessing a
/// fallback — callers must treat that as a configuration error.
AppFlavor? parseAppFlavor(String value) {
  switch (value.trim().toLowerCase()) {
    case 'dev':
      return AppFlavor.dev;
    case 'staging':
      return AppFlavor.staging;
    case 'prod':
      return AppFlavor.prod;
    case '':
      return null;
    default:
      return null;
  }
}
