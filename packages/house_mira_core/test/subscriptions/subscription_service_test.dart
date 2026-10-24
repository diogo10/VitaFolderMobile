import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira_core/observability/app_logger.dart';
import 'package:house_mira_core/observability/crash_reporter.dart';
import 'package:house_mira_core/subscriptions/subscription_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class _RecordingCrashReporter implements CrashReporter {
  final List<String> logs = [];
  final List<Object> errors = [];

  @override
  Future<void> log(String message) async => logs.add(message);

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, Object?>? context,
    bool fatal = false,
  }) async => errors.add(error);

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}
}

class _FakePurchasesWrapper extends PurchasesWrapper {
  PurchasesConfiguration? configuredWith;
  LogLevel? logLevel;
  Object? configureError;
  int configureCalls = 0;
  CustomerInfo? customerInfo;
  Object? customerInfoError;
  int customerInfoCalls = 0;
  Offerings? offerings;
  Object? offeringsError;
  int offeringsCalls = 0;

  @override
  Future<void> configure(PurchasesConfiguration configuration) async {
    configureCalls++;
    if (configureError != null) {
      throw configureError!;
    }
    configuredWith = configuration;
  }

  @override
  Future<void> setLogLevel(LogLevel level) async {
    logLevel = level;
  }

  @override
  Future<CustomerInfo> getCustomerInfo() async {
    customerInfoCalls++;
    if (customerInfoError != null) {
      throw customerInfoError!;
    }
    return customerInfo!;
  }

  @override
  Future<Offerings> getOfferings() async {
    offeringsCalls++;
    if (offeringsError != null) {
      throw offeringsError!;
    }
    return offerings!;
  }
}

AppLogger _silentLogger() => AppLogger(sink: (_) {});

CustomerInfo _customerInfo({required bool proActive}) {
  const entitlement = EntitlementInfo(
    'housemira_pro',
    true,
    true,
    '',
    '',
    '',
    true,
  );
  final active = proActive
      ? {'housemira_pro': entitlement}
      : const <String, EntitlementInfo>{};
  return CustomerInfo(
    EntitlementInfos(const {}, active),
    const {},
    const [],
    const [],
    const [],
    '',
    '',
    const {},
    '',
  );
}

Offerings _offerings({
  bool monthly = true,
  bool annual = true,
  bool current = true,
}) {
  const monthlyProduct = StoreProduct(
    'housemira_pro_monthly_test',
    'Monthly Pro',
    'HouseMira Pro Monthly',
    7.99,
    r'$7.99',
    'USD',
    pricePerMonthString: r'$7.99',
  );
  const annualProduct = StoreProduct(
    'housemira_pro_annual_test',
    'Annual Pro',
    'HouseMira Pro Annual',
    49.99,
    r'$49.99',
    'USD',
    pricePerMonthString: r'$4.17',
  );
  const context = PresentedOfferingContext('default', null, null);
  const monthlyPackage = Package(
    r'$rc_monthly',
    PackageType.monthly,
    monthlyProduct,
    context,
  );
  const annualPackage = Package(
    r'$rc_annual',
    PackageType.annual,
    annualProduct,
    context,
  );
  final offering = Offering(
    'default',
    '',
    const {},
    [if (monthly) monthlyPackage, if (annual) annualPackage],
    monthly: monthly ? monthlyPackage : null,
    annual: annual ? annualPackage : null,
  );
  if (!current) {
    return const Offerings({});
  }
  return Offerings({'default': offering}, current: offering);
}

void main() {
  group('SubscriptionService.initialize', () {
    test('configures with the Apple key on iOS', () async {
      final purchases = _FakePurchasesWrapper();
      final service = SubscriptionService(
        purchases: purchases,
        logger: _silentLogger(),
        platformOverride: TargetPlatform.iOS,
      );

      final initialized = await service.initialize(
        appleApiKey: 'fake-apple-key',
        googleApiKey: 'fake-google-key',
      );

      expect(initialized, isTrue);
      expect(service.isInitialized, isTrue);
      expect(purchases.configuredWith?.apiKey, 'fake-apple-key');
      expect(purchases.logLevel, isNotNull);
    });

    test('configures with the Apple key on macOS', () async {
      final purchases = _FakePurchasesWrapper();
      final service = SubscriptionService(
        purchases: purchases,
        logger: _silentLogger(),
        platformOverride: TargetPlatform.macOS,
      );

      final initialized = await service.initialize(
        appleApiKey: 'fake-apple-key',
        googleApiKey: 'fake-google-key',
      );

      expect(initialized, isTrue);
      expect(purchases.configuredWith?.apiKey, 'fake-apple-key');
    });

    test('configures with the Google key on Android', () async {
      final purchases = _FakePurchasesWrapper();
      final service = SubscriptionService(
        purchases: purchases,
        logger: _silentLogger(),
        platformOverride: TargetPlatform.android,
      );

      final initialized = await service.initialize(
        appleApiKey: 'fake-apple-key',
        googleApiKey: 'fake-google-key',
      );

      expect(initialized, isTrue);
      expect(service.isInitialized, isTrue);
      expect(purchases.configuredWith?.apiKey, 'fake-google-key');
    });

    test('skips when the platform key is missing', () async {
      final purchases = _FakePurchasesWrapper();
      final service = SubscriptionService(
        purchases: purchases,
        logger: _silentLogger(),
        platformOverride: TargetPlatform.android,
      );

      final initialized = await service.initialize(
        appleApiKey: 'fake-apple-key',
        googleApiKey: '',
      );

      expect(initialized, isFalse);
      expect(service.isInitialized, isFalse);
      expect(purchases.configureCalls, 0);
    });

    test('skips on unsupported platforms', () async {
      final purchases = _FakePurchasesWrapper();
      final service = SubscriptionService(
        purchases: purchases,
        logger: _silentLogger(),
        platformOverride: TargetPlatform.linux,
      );

      final initialized = await service.initialize(
        appleApiKey: 'fake-apple-key',
        googleApiKey: 'fake-google-key',
      );

      expect(initialized, isFalse);
      expect(service.isInitialized, isFalse);
      expect(purchases.configureCalls, 0);
    });

    test(
      'returns false and stays uninitialized when configure throws',
      () async {
        final purchases = _FakePurchasesWrapper()
          ..configureError = StateError('store unavailable');
        final service = SubscriptionService(
          purchases: purchases,
          logger: _silentLogger(),
          platformOverride: TargetPlatform.iOS,
        );

        final initialized = await service.initialize(
          appleApiKey: 'fake-apple-key',
          googleApiKey: '',
        );

        expect(initialized, isFalse);
        expect(service.isInitialized, isFalse);
      },
    );

    test('second initialize is a no-op once configured', () async {
      final purchases = _FakePurchasesWrapper();
      final service = SubscriptionService(
        purchases: purchases,
        logger: _silentLogger(),
        platformOverride: TargetPlatform.android,
      );

      expect(
        await service.initialize(
          appleApiKey: '',
          googleApiKey: 'fake-google-key',
        ),
        isTrue,
      );
      expect(
        await service.initialize(appleApiKey: '', googleApiKey: 'other-key'),
        isTrue,
      );
      expect(purchases.configureCalls, 1);
      expect(purchases.configuredWith?.apiKey, 'fake-google-key');
    });
  });

  group('SubscriptionService.isPro', () {
    Future<SubscriptionService> initializedService(
      _FakePurchasesWrapper purchases,
    ) async {
      final service = SubscriptionService(
        purchases: purchases,
        logger: _silentLogger(),
        platformOverride: TargetPlatform.android,
      );
      expect(
        await service.initialize(
          appleApiKey: '',
          googleApiKey: 'fake-google-key',
        ),
        isTrue,
      );
      return service;
    }

    test('false when billing is uninitialized', () async {
      final service = SubscriptionService(
        purchases: _FakePurchasesWrapper(),
        logger: _silentLogger(),
        platformOverride: TargetPlatform.android,
      );

      expect(await service.isPro(), isFalse);
    });

    test('true when the pro entitlement is active', () async {
      final purchases = _FakePurchasesWrapper()
        ..customerInfo = _customerInfo(proActive: true);
      final service = await initializedService(purchases);

      expect(await service.isPro(), isTrue);
    });

    test('false when the pro entitlement is inactive', () async {
      final purchases = _FakePurchasesWrapper()
        ..customerInfo = _customerInfo(proActive: false);
      final service = await initializedService(purchases);

      expect(await service.isPro(), isFalse);
    });

    test('false and never throws when the lookup fails', () async {
      final purchases = _FakePurchasesWrapper()
        ..customerInfoError = StateError('store unavailable');
      final service = await initializedService(purchases);

      expect(await service.isPro(), isFalse);
    });

    test(
      'disables billing for the session when RevenueCat rejects the key',
      () async {
        final purchases = _FakePurchasesWrapper()
          ..customerInfoError = PlatformException(
            code: '11',
            message: 'There was a credentials issue.',
            details: {'readableErrorCode': 'invalidCredentialsError'},
          );
        final service = await initializedService(purchases);

        expect(await service.isPro(), isFalse);
        expect(service.isBillingAvailable, isFalse);
        // Retrying a rejected key cannot succeed, so later lookups never hit
        // the store and the paywall falls back to its error state.
        expect(await service.isPro(), isFalse);
        expect(await service.getOfferingPrices(), isNull);
        expect(purchases.customerInfoCalls, 1);
        expect(purchases.offeringsCalls, 0);
      },
    );

    test('keeps billing available after a transient store failure', () async {
      final purchases = _FakePurchasesWrapper()
        ..customerInfoError = PlatformException(
          code: '10',
          message: 'Network error.',
          details: {'readableErrorCode': 'networkError'},
        );
      final service = await initializedService(purchases);

      expect(await service.isPro(), isFalse);
      expect(service.isBillingAvailable, isTrue);

      purchases
        ..customerInfoError = null
        ..customerInfo = _customerInfo(proActive: true);
      expect(await service.isPro(), isTrue);
      expect(purchases.customerInfoCalls, 2);
    });

    test(
      'a rejected key is logged once and never reported as a crash',
      () async {
        final reporter = _RecordingCrashReporter();
        final purchases = _FakePurchasesWrapper()
          ..customerInfoError = PlatformException(
            code: '11',
            message: 'There was a credentials issue.',
            details: {'readableErrorCode': 'invalidCredentialsError'},
          );
        final service = SubscriptionService(
          purchases: purchases,
          logger: AppLogger(crashReporter: reporter, sink: (_) {}),
          platformOverride: TargetPlatform.android,
        );
        expect(
          await service.initialize(appleApiKey: '', googleApiKey: 'bad-key'),
          isTrue,
        );

        expect(await service.isPro(), isFalse);
        expect(await service.isPro(), isFalse);

        // Fail-closed is a handled outcome: the credentials mistake stays a
        // breadcrumb, not a Crashlytics non-fatal (issue `704f61c6`).
        expect(reporter.errors, isEmpty);
        expect(
          reporter.logs.where(
            (line) => line.contains('revenuecat billing disabled'),
          ),
          hasLength(1),
        );
      },
    );

    test('caches a successful lookup within the TTL', () async {
      final purchases = _FakePurchasesWrapper()
        ..customerInfo = _customerInfo(proActive: true);
      final service = await initializedService(purchases);

      expect(await service.isPro(), isTrue);
      expect(await service.isPro(), isTrue);
      expect(purchases.customerInfoCalls, 1);
    });

    test('invalidateProCache forces the next lookup to refetch', () async {
      final purchases = _FakePurchasesWrapper()
        ..customerInfo = _customerInfo(proActive: false);
      final service = await initializedService(purchases);

      expect(await service.isPro(), isFalse);
      purchases.customerInfo = _customerInfo(proActive: true);
      // Still cached: upgrade not visible until invalidated.
      expect(await service.isPro(), isFalse);
      service.invalidateProCache();
      expect(await service.isPro(), isTrue);
      expect(purchases.customerInfoCalls, 2);
    });

    test('failed lookups are never cached', () async {
      final purchases = _FakePurchasesWrapper()
        ..customerInfoError = StateError('store unavailable');
      final service = await initializedService(purchases);

      expect(await service.isPro(), isFalse);
      purchases
        ..customerInfoError = null
        ..customerInfo = _customerInfo(proActive: true);
      expect(await service.isPro(), isTrue);
      expect(purchases.customerInfoCalls, 2);
    });

    test(
      'a different userId refetches instead of reading stale cache',
      () async {
        final purchases = _FakePurchasesWrapper()
          ..customerInfo = _customerInfo(proActive: false);
        final service = await initializedService(purchases);

        expect(await service.isPro(userId: 'user-a'), isFalse);
        // The SDK now reports pro for the next user: the cached `false`
        // for user-a must not leak across the account switch.
        purchases.customerInfo = _customerInfo(proActive: true);
        expect(await service.isPro(userId: 'user-b'), isTrue);
        expect(purchases.customerInfoCalls, 2);
      },
    );

    test(
      'logging out (null userId) refetches instead of reading cache',
      () async {
        final purchases = _FakePurchasesWrapper()
          ..customerInfo = _customerInfo(proActive: true);
        final service = await initializedService(purchases);

        expect(await service.isPro(userId: 'user-a'), isTrue);
        purchases.customerInfo = _customerInfo(proActive: false);
        expect(await service.isPro(), isFalse);
        // The null-keyed `false` must not satisfy a later user-a lookup:
        // it refetches and sees the fresh value.
        purchases.customerInfo = _customerInfo(proActive: true);
        expect(await service.isPro(userId: 'user-a'), isTrue);
        expect(purchases.customerInfoCalls, 3);
      },
    );

    test('invalidateProCache drops the user-scoped entry', () async {
      final purchases = _FakePurchasesWrapper()
        ..customerInfo = _customerInfo(proActive: false);
      final service = await initializedService(purchases);

      expect(await service.isPro(userId: 'user-a'), isFalse);
      purchases.customerInfo = _customerInfo(proActive: true);
      service.invalidateProCache();
      expect(await service.isPro(userId: 'user-a'), isTrue);
      expect(purchases.customerInfoCalls, 2);
    });
  });

  group('SubscriptionService.initialize test store', () {
    Future<SubscriptionService> testStoreService(
      _FakePurchasesWrapper purchases, {
      String testApiKey = 'test_fake-key',
      bool useTestStore = true,
      bool release = false,
    }) async {
      final service = SubscriptionService(
        purchases: purchases,
        logger: _silentLogger(),
        platformOverride: TargetPlatform.android,
        releaseOverride: release,
      );
      expect(
        await service.initialize(
          appleApiKey: 'fake-apple-key',
          googleApiKey: 'fake-google-key',
          testApiKey: testApiKey,
          useTestStore: useTestStore,
        ),
        isTrue,
      );
      return service;
    }

    test('uses the test key when requested', () async {
      final purchases = _FakePurchasesWrapper();
      final service = await testStoreService(purchases);

      expect(service.isInitialized, isTrue);
      expect(service.isUsingTestStore, isTrue);
      expect(purchases.configuredWith?.apiKey, 'test_fake-key');
    });

    test('falls back to the platform key without a test key', () async {
      final purchases = _FakePurchasesWrapper();
      final service = SubscriptionService(
        purchases: purchases,
        logger: _silentLogger(),
        platformOverride: TargetPlatform.android,
      );

      expect(
        await service.initialize(
          appleApiKey: 'fake-apple-key',
          googleApiKey: 'fake-google-key',
          useTestStore: true,
        ),
        isTrue,
      );
      expect(service.isUsingTestStore, isFalse);
      expect(purchases.configuredWith?.apiKey, 'fake-google-key');
    });

    test('ignores the test key when not requested', () async {
      final purchases = _FakePurchasesWrapper();
      final service = SubscriptionService(
        purchases: purchases,
        logger: _silentLogger(),
        platformOverride: TargetPlatform.android,
      );

      expect(
        await service.initialize(
          appleApiKey: 'fake-apple-key',
          googleApiKey: 'fake-google-key',
          testApiKey: 'test_fake-key',
        ),
        isTrue,
      );
      expect(service.isUsingTestStore, isFalse);
      expect(purchases.configuredWith?.apiKey, 'fake-google-key');
    });

    test('skips a test key in release builds', () async {
      final purchases = _FakePurchasesWrapper();
      final service = SubscriptionService(
        purchases: purchases,
        logger: _silentLogger(),
        platformOverride: TargetPlatform.android,
        releaseOverride: true,
      );

      expect(
        await service.initialize(
          appleApiKey: 'fake-apple-key',
          googleApiKey: 'fake-google-key',
          testApiKey: 'test_fake-key',
          useTestStore: true,
        ),
        isFalse,
      );
      expect(service.isInitialized, isFalse);
      expect(service.isUsingTestStore, isFalse);
      expect(purchases.configureCalls, 0);
    });

    test('configures a platform key in release builds', () async {
      final purchases = _FakePurchasesWrapper();
      final service = SubscriptionService(
        purchases: purchases,
        logger: _silentLogger(),
        platformOverride: TargetPlatform.iOS,
        releaseOverride: true,
      );

      expect(
        await service.initialize(
          appleApiKey: 'fake-apple-key',
          googleApiKey: 'fake-google-key',
        ),
        isTrue,
      );
      expect(purchases.configuredWith?.apiKey, 'fake-apple-key');
    });
  });

  group('SubscriptionService.getOfferingPrices', () {
    Future<SubscriptionService> pricesService(
      _FakePurchasesWrapper purchases,
    ) async {
      final service = SubscriptionService(
        purchases: purchases,
        logger: _silentLogger(),
        platformOverride: TargetPlatform.android,
      );
      expect(
        await service.initialize(
          appleApiKey: '',
          googleApiKey: 'fake-google-key',
        ),
        isTrue,
      );
      return service;
    }

    test('null when billing is uninitialized', () async {
      final service = SubscriptionService(
        purchases: _FakePurchasesWrapper(),
        logger: _silentLogger(),
        platformOverride: TargetPlatform.android,
      );

      expect(await service.getOfferingPrices(), isNull);
    });

    test('maps the monthly and annual packages', () async {
      final purchases = _FakePurchasesWrapper()..offerings = _offerings();
      final service = await pricesService(purchases);

      final prices = await service.getOfferingPrices();

      expect(purchases.offeringsCalls, 1);
      expect(prices?.monthly.packageId, r'$rc_monthly');
      expect(prices?.monthly.price, 7.99);
      expect(prices?.monthly.priceString, r'$7.99');
      expect(prices?.monthly.currencyCode, 'USD');
      expect(prices?.monthly.pricePerMonthString, r'$7.99');
      expect(prices?.annual.packageId, r'$rc_annual');
      expect(prices?.annual.price, 49.99);
      expect(prices?.annual.priceString, r'$49.99');
      expect(prices?.annual.currencyCode, 'USD');
      expect(prices?.annual.pricePerMonthString, r'$4.17');
    });

    test('null when there is no current offering', () async {
      final purchases = _FakePurchasesWrapper()
        ..offerings = _offerings(current: false);
      final service = await pricesService(purchases);

      expect(await service.getOfferingPrices(), isNull);
    });

    test('null when the monthly package is missing', () async {
      final purchases = _FakePurchasesWrapper()
        ..offerings = _offerings(monthly: false);
      final service = await pricesService(purchases);

      expect(await service.getOfferingPrices(), isNull);
    });

    test('null when the annual package is missing', () async {
      final purchases = _FakePurchasesWrapper()
        ..offerings = _offerings(annual: false);
      final service = await pricesService(purchases);

      expect(await service.getOfferingPrices(), isNull);
    });

    test('null and never throws when the lookup fails', () async {
      final purchases = _FakePurchasesWrapper()
        ..offeringsError = StateError('store unavailable');
      final service = await pricesService(purchases);

      expect(await service.getOfferingPrices(), isNull);
    });
  });
}
