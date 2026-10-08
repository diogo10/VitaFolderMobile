import 'package:flutter/foundation.dart';
import 'package:house_mira/core/observability/app_logger.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Thin wrapper around the RevenueCat static API.
///
/// `Purchases` is a process-wide singleton with only static entry points,
/// which cannot be faked in tests. [SubscriptionService] talks to this
/// wrapper instead so tests can substitute a recording fake.
class PurchasesWrapper {
  /// Configures the shared RevenueCat instance.
  Future<void> configure(PurchasesConfiguration configuration) =>
      Purchases.configure(configuration);

  /// Sets the SDK log verbosity.
  Future<void> setLogLevel(LogLevel level) => Purchases.setLogLevel(level);

  /// Fetches the current customer info (entitlements).
  Future<CustomerInfo> getCustomerInfo() => Purchases.getCustomerInfo();
}

/// Initializes and owns the RevenueCat SDK instance.
///
/// Initial setup only: configures the shared `Purchases` instance with the
/// platform's public API key (Apple on iOS/macOS, Google on Android).
///
/// A missing key for the current platform (or an unsupported platform such
/// as web, which needs a separate web-billing config) skips initialization
/// and returns `false`. Billing is best-effort like notifications and
/// analytics, so the app never fails to start over store configuration —
/// failures are reported through [AppLogger] instead of thrown.
class SubscriptionService {
  /// Creates the service.
  ///
  /// [platformOverride] is a testing seam for [defaultTargetPlatform]
  /// (e.g. force [TargetPlatform.android] on a Linux test host).
  SubscriptionService({
    PurchasesWrapper? purchases,
    AppLogger? logger,
    TargetPlatform? platformOverride,
  }) : _purchases = purchases ?? PurchasesWrapper(),
       _logger = logger ?? AppLogger(),
       _platformOverride = platformOverride;

  /// RevenueCat entitlement granting unlimited reminders and notes.
  static const String proEntitlementId = 'pro';

  final PurchasesWrapper _purchases;
  final AppLogger _logger;
  final TargetPlatform? _platformOverride;

  bool _initialized = false;

  /// Whether [initialize] has successfully configured the SDK.
  bool get isInitialized => _initialized;

  /// Whether the user holds the paid entitlement ([proEntitlementId]).
  ///
  /// Returns `false` when billing is uninitialized or the lookup fails
  /// (fail-closed: free limits apply). Never throws: every failure is
  /// logged and reported instead.
  Future<bool> isPro() async {
    if (!_initialized) {
      return false;
    }
    try {
      final info = await _purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(proEntitlementId);
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'entitlement check failed',
        tag: 'subscriptions',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Configures the RevenueCat SDK for the current platform.
  ///
  /// Returns `true` when the shared `Purchases` instance is configured,
  /// `false` when initialization was skipped (missing key, unsupported
  /// platform) or failed. Never throws: every failure is logged and
  /// reported instead.
  Future<bool> initialize({
    required String appleApiKey,
    required String googleApiKey,
  }) async {
    if (_initialized) {
      return true;
    }
    final platform = _platformOverride ?? defaultTargetPlatform;
    final String apiKey;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      apiKey = appleApiKey;
    } else if (platform == TargetPlatform.android) {
      apiKey = googleApiKey;
    } else {
      apiKey = '';
    }
    if (apiKey.isEmpty) {
      _logger.warning(
        'revenuecat init skipped',
        tag: 'subscriptions',
        context: {'platform': platform.name, 'configured': false},
      );
      return false;
    }
    try {
      await _purchases.setLogLevel(
        kDebugMode ? LogLevel.debug : LogLevel.error,
      );
      await _purchases.configure(PurchasesConfiguration(apiKey));
      _initialized = true;
      _logger.info(
        'revenuecat initialized',
        tag: 'subscriptions',
        context: {'platform': platform.name},
      );
      return true;
    } on Object catch (error, stackTrace) {
      _logger.error(
        'revenuecat init failed',
        tag: 'subscriptions',
        context: {'platform': platform.name},
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
