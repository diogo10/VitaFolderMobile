import 'package:house_mira/core/config/app_flavor.dart';

/// Runtime backend configuration for the app.
///
/// Values come from compile-time `--dart-define`s (or
/// `--dart-define-from-file=env/<flavor>.json`), never from hardcoded
/// literals in `lib/`. Missing or invalid values throw [StateError] at
/// startup so misconfiguration fails fast instead of silently pointing at
/// the wrong backend.
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    this.revenueCatAppleApiKey = '',
    this.revenueCatGoogleApiKey = '',
  });

  /// Reads the configuration from `--dart-define` values.
  ///
  /// Required keys: `APP_FLAVOR` (`dev`|`staging`|`prod`), `SUPABASE_URL`
  /// (https URL of the flavor's Supabase project),
  /// `SUPABASE_PUBLISHABLE_KEY` (the project's publishable key).
  /// Throws [StateError] when any key is missing or invalid.
  ///
  /// Optional keys: `REVENUECAT_APPLE_API_KEY` (RevenueCat public Apple key,
  /// dashboard → Project Settings → API keys → App specific keys) and
  /// `REVENUECAT_GOOGLE_API_KEY` (RevenueCat public Google key). Empty means
  /// billing is unconfigured and the RevenueCat SDK init is skipped —
  /// unlike Supabase, billing is best-effort so the app still runs without
  /// store keys (e.g. before the store listings exist).
  factory AppConfig.fromEnvironment() => AppConfig.fromDefines(
    flavorRaw: const String.fromEnvironment('APP_FLAVOR'),
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabasePublishableKey: const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    ),
    revenueCatAppleApiKey: const String.fromEnvironment(
      'REVENUECAT_APPLE_API_KEY',
    ),
    revenueCatGoogleApiKey: const String.fromEnvironment(
      'REVENUECAT_GOOGLE_API_KEY',
    ),
  );

  /// Testable core of [AppConfig.fromEnvironment]: validates raw define
  /// values.
  ///
  /// Split out because `String.fromEnvironment` is compile-time only and
  /// cannot be stubbed in unit tests.
  factory AppConfig.fromDefines({
    required String flavorRaw,
    required String supabaseUrl,
    required String supabasePublishableKey,
    required String revenueCatAppleApiKey,
    required String revenueCatGoogleApiKey,
  }) {
    final flavor = parseAppFlavor(flavorRaw);
    if (flavor == null) {
      throw StateError(
        'Missing or invalid APP_FLAVOR "$flavorRaw". '
        'Pass --dart-define=APP_FLAVOR=dev|staging|prod '
        'or --dart-define-from-file=env/<flavor>.json.',
      );
    }
    final uri = Uri.tryParse(supabaseUrl);
    if (supabaseUrl.isEmpty ||
        uri == null ||
        !uri.isAbsolute ||
        uri.scheme != 'https' ||
        uri.host.isEmpty) {
      throw StateError(
        'Missing or invalid SUPABASE_URL "$supabaseUrl". '
        'Expected the https URL of the ${flavor.name} Supabase project.',
      );
    }
    if (supabasePublishableKey.isEmpty) {
      throw StateError(
        'Missing SUPABASE_PUBLISHABLE_KEY for flavor "${flavor.name}". '
        'Use the publishable key from the Supabase dashboard '
        '(Project Settings → API). Server-side keys must never be '
        'used in the client.',
      );
    }
    return AppConfig(
      flavor: flavor,
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: supabasePublishableKey,
      revenueCatAppleApiKey: revenueCatAppleApiKey,
      revenueCatGoogleApiKey: revenueCatGoogleApiKey,
    );
  }

  final AppFlavor flavor;
  final String supabaseUrl;
  final String supabasePublishableKey;

  /// RevenueCat public Apple API key (`appl_…`). Empty when unconfigured.
  final String revenueCatAppleApiKey;

  /// RevenueCat public Google API key (`goog_…`). Empty when unconfigured.
  final String revenueCatGoogleApiKey;
}
