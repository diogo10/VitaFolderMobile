import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:house_mira_core/observability/app_logger.dart';

/// Firebase Remote Config client for feature flags.
///
/// Flags are fetched once at startup and cached for the life of the
/// process. Every flag defaults to `false` so the app ships with all
/// remote gates off until explicitly enabled in the Firebase console.
///
/// [remoteConfig] is a testing seam; it defaults to `null`, which makes
/// every flag read as `false` until [initialize] installs the live
/// [FirebaseRemoteConfig.instance] (only called after Firebase is
/// initialized in production).
class RemoteConfigService {
  /// Creates the service.
  ///
  /// Pass [remoteConfig] to substitute a fake in tests. When omitted, all
  /// flags read as `false` (limits and paywall disabled) until
  /// [initialize] is called.
  RemoteConfigService({
    FirebaseRemoteConfig? remoteConfig,
    required AppLogger logger,
  }) : _remoteConfig = remoteConfig,
       _logger = logger;

  FirebaseRemoteConfig? _remoteConfig;
  final AppLogger _logger;

  /// Feature flag: when `true`, usage limits and paywalls are active;
  /// when `false` (the default), both are disabled.
  ///
  /// Returns `false` before [initialize] has installed a live config.
  bool get enableLimitAndPaywall {
    final remoteConfig = _remoteConfig;
    if (remoteConfig == null) return false;
    return remoteConfig.getBool(_kEnableLimitAndPaywall);
  }

  static const _kEnableLimitAndPaywall = 'enable_limit_and_paywall';

  /// Feature flag: when `true`, the "Sign in with Apple" button is
  /// rendered; when `false` (the default), the button is hidden.
  ///
  /// The flag only gates the button; the platform gate (native Sign in
  /// with Apple exists on Apple platforms only) still applies, so the
  /// button is shown when the flag is on **and** the platform supports
  /// it.
  ///
  /// Returns `false` before [initialize] has installed a live config.
  bool get showAppleLogin {
    final remoteConfig = _remoteConfig;
    if (remoteConfig == null) return false;
    return remoteConfig.getBool(_kShowAppleLogin);
  }

  static const _kShowAppleLogin = 'show_apple_login';

  /// Sets defaults, fetches, and activates Remote Config.
  ///
  /// Installs the live [FirebaseRemoteConfig.instance] on first call when
  /// none was supplied, so Firebase must be initialized before this runs
  /// (it is: production calls this after `Firebase.initializeApp`).
  /// Failures are logged and the cached defaults are used, so a remote
  /// config outage never blocks the app and never accidentally enables
  /// paid gating. The default for [_kEnableLimitAndPaywall] and
  /// [_kShowAppleLogin] is `false`.
  Future<void> initialize() async {
    _remoteConfig ??= FirebaseRemoteConfig.instance;
    await _remoteConfig!.setDefaults(const {
      _kEnableLimitAndPaywall: false,
      _kShowAppleLogin: false,
    });
    try {
      final activated = await _remoteConfig!.fetchAndActivate();
      _logger.info(
        'remote config activated',
        tag: 'remote_config',
        context: {
          'enable_limit_and_paywall': enableLimitAndPaywall,
          'show_apple_login': showAppleLogin,
          'activated': activated,
        },
      );
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'remote config fetch failed, using defaults',
        tag: 'remote_config',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
