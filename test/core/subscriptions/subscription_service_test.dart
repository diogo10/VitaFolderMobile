import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/observability/app_logger.dart';
import 'package:house_mira/core/subscriptions/subscription_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class _FakePurchasesWrapper extends PurchasesWrapper {
  PurchasesConfiguration? configuredWith;
  LogLevel? logLevel;
  Error? configureError;
  int configureCalls = 0;
  CustomerInfo? customerInfo;
  Error? customerInfoError;

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
    if (customerInfoError != null) {
      throw customerInfoError!;
    }
    return customerInfo!;
  }
}

AppLogger _silentLogger() => AppLogger(sink: (_) {});

CustomerInfo _customerInfo({required bool proActive}) {
  const entitlement = EntitlementInfo('pro', true, true, '', '', '', true);
  final active = proActive
      ? {'pro': entitlement}
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
  });
}
