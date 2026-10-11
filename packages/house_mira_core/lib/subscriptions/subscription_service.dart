import 'package:flutter/foundation.dart';
import 'package:house_mira_core/observability/app_logger.dart';
import 'package:house_mira_core/subscriptions/store_package_price.dart';
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

  /// Fetches the available offerings (products for the paywall).
  Future<Offerings> getOfferings() => Purchases.getOfferings();
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
  /// [releaseOverride] is a testing seam for [kReleaseMode] so the
  /// Test Store release guard is unit-testable.
  SubscriptionService({
    PurchasesWrapper? purchases,
    AppLogger? logger,
    TargetPlatform? platformOverride,
    bool? releaseOverride,
  }) : _purchases = purchases ?? PurchasesWrapper(),
       _logger = logger ?? AppLogger(),
       _platformOverride = platformOverride,
       _releaseOverride = releaseOverride;

  /// RevenueCat entitlement granting unlimited reminders and notes.
  static const String proEntitlementId = 'housemira_pro';

  /// How long a successful entitlement lookup stays cached.
  ///
  /// Views pre-check the free-tier cap before opening an editor and the
  /// cubit re-checks on save; without a cache that flow costs two
  /// `getCustomerInfo()` round-trips plus two count queries. Caching the
  /// paid bit briefly collapses the pair to one billing lookup per flow
  /// while staying fresh enough for post-purchase upgrades (call
  /// [invalidateProCache] after a successful purchase/restore to refresh
  /// immediately). The cache is keyed by the calling [isPro] `userId`, so
  /// an account switch or logout never reads another user's entitlement.
  static const Duration proCacheTtl = Duration(seconds: 30);

  final PurchasesWrapper _purchases;
  final AppLogger _logger;
  final TargetPlatform? _platformOverride;
  final bool? _releaseOverride;

  bool _initialized = false;
  bool _usingTestStore = false;

  /// Whether [initialize] has successfully configured the SDK.
  bool get isInitialized => _initialized;

  /// Whether the SDK was configured with the RevenueCat Test Store key.
  ///
  /// Callers use this to pick dev-only fallbacks (e.g. the mocked paywall
  /// catalog when offerings fail). `false` when uninitialized.
  bool get isUsingTestStore => _initialized && _usingTestStore;

  bool? _cachedIsPro;
  DateTime? _cachedIsProAt;
  String? _cachedUserId;

  /// Drops the cached [isPro] result so the next lookup hits the store.
  ///
  /// Call after a purchase, restore, or account change.
  void invalidateProCache() {
    _cachedIsPro = null;
    _cachedIsProAt = null;
    _cachedUserId = null;
  }

  /// Whether the user holds the paid entitlement ([proEntitlementId]).
  ///
  /// Returns `false` when billing is uninitialized or the lookup fails
  /// (fail-closed: free limits apply). Never throws: every failure is
  /// logged and reported instead. Successful lookups are cached for
  /// [proCacheTtl] so a view pre-check plus the create-time re-check
  /// costs one billing lookup per flow; failures are never cached.
  ///
  /// Pass the current `AuthService.currentUserId` as [userId] so the cache
  /// is scoped to one account: a lookup for a different user (including
  /// `null` after logout) always refetches instead of reading stale data.
  Future<bool> isPro({String? userId}) async {
    if (!_initialized) {
      return false;
    }
    final cached = _cachedIsPro;
    final cachedAt = _cachedIsProAt;
    if (cached != null && cachedAt != null && _cachedUserId == userId) {
      final age = DateTime.now().difference(cachedAt);
      if (age < proCacheTtl && !age.isNegative) {
        return cached;
      }
    }
    try {
      final info = await _purchases.getCustomerInfo();
      final pro = info.entitlements.active.containsKey(proEntitlementId);
      _cachedIsPro = pro;
      _cachedIsProAt = DateTime.now();
      _cachedUserId = userId;
      return pro;
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

  /// Monthly and annual prices of the current offering for the paywall.
  ///
  /// Returns `null` when billing is uninitialized, there is no current
  /// offering, a package is missing, or the lookup fails (fail-closed:
  /// callers fall back to the mocked catalog on the Test Store and to an
  /// error state in production). Never throws.
  Future<OfferingPrices?> getOfferingPrices() async {
    if (!_initialized) {
      return null;
    }
    try {
      final offerings = await _purchases.getOfferings();
      final current = offerings.current;
      final monthly = current?.monthly;
      final annual = current?.annual;
      if (monthly == null || annual == null) {
        return null;
      }
      return OfferingPrices(
        monthly: StorePackagePrice.fromPackage(monthly),
        annual: StorePackagePrice.fromPackage(annual),
      );
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'offerings fetch failed',
        tag: 'subscriptions',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Configures the RevenueCat SDK for the current platform.
  ///
  /// Pass [testApiKey] with [useTestStore] (dev + debug builds) to talk to
  /// the RevenueCat Test Store instead of the real stores: purchases show a
  /// local dialog, no sandbox accounts needed. Production builds must use
  /// the platform keys — a `test_` key in a release build skips
  /// initialization (the SDK crashes on purpose with Test Store keys), so a
  /// misconfigured release falls back to free limits instead of crashing.
  ///
  /// Returns `true` when the shared `Purchases` instance is configured,
  /// `false` when initialization was skipped (missing key, Test Store key
  /// in release, unsupported platform) or failed. Never throws: every
  /// failure is logged and reported instead.
  Future<bool> initialize({
    required String appleApiKey,
    required String googleApiKey,
    String testApiKey = '',
    bool useTestStore = false,
  }) async {
    if (_initialized) {
      return true;
    }
    final release = _releaseOverride ?? kReleaseMode;
    final platform = _platformOverride ?? defaultTargetPlatform;
    final String apiKey;
    var usingTestStore = false;
    if (useTestStore && testApiKey.isNotEmpty) {
      apiKey = testApiKey;
      usingTestStore = true;
    } else if (platform == TargetPlatform.iOS ||
        platform == TargetPlatform.macOS) {
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
    if (release && apiKey.startsWith('test_')) {
      _logger.warning(
        'revenuecat init skipped',
        tag: 'subscriptions',
        context: {
          'platform': platform.name,
          'configured': false,
          'reason': 'test-store-key-in-release',
        },
      );
      return false;
    }
    try {
      await _purchases.setLogLevel(
        kDebugMode ? LogLevel.debug : LogLevel.error,
      );
      await _purchases.configure(PurchasesConfiguration(apiKey));
      _initialized = true;
      _usingTestStore = usingTestStore;
      _logger.info(
        'revenuecat initialized',
        tag: 'subscriptions',
        context: {'platform': platform.name, 'testStore': usingTestStore},
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
