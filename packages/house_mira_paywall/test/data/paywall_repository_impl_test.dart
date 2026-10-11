import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira_core/subscriptions/store_package_price.dart';
import 'package:house_mira_core/subscriptions/subscription_service.dart';
import 'package:house_mira_paywall/data/repository/paywall_repository_impl.dart';

/// Returns canned offering prices without touching the store.
class _FakeSubscriptions extends SubscriptionService {
  _FakeSubscriptions({this.prices, this.testStore = false});

  final OfferingPrices? prices;
  final bool testStore;

  @override
  Future<OfferingPrices?> getOfferingPrices() async => prices;

  @override
  bool get isUsingTestStore => testStore;
}

/// Throws from the offerings lookup to exercise the catch path.
class _ThrowingSubscriptions extends SubscriptionService {
  _ThrowingSubscriptions({this.testStore = false});

  final bool testStore;

  @override
  Future<OfferingPrices?> getOfferingPrices() async {
    throw StateError('store unavailable');
  }

  @override
  bool get isUsingTestStore => testStore;
}

const _prices = OfferingPrices(
  monthly: StorePackagePrice(
    packageId: r'$rc_monthly',
    price: 7.99,
    priceString: r'$7.99',
    currencyCode: 'USD',
    pricePerMonthString: r'$7.99',
  ),
  annual: StorePackagePrice(
    packageId: r'$rc_annual',
    price: 49.99,
    priceString: r'$49.99',
    currencyCode: 'USD',
    pricePerMonthString: r'$4.17',
  ),
);

void main() {
  group('PaywallRepositoryImpl.getPaywallData', () {
    test('maps live offerings to plans', () async {
      final repository = PaywallRepositoryImpl(
        subscriptionService: _FakeSubscriptions(prices: _prices),
      );

      final result = await repository.getPaywallData();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (data) {
          expect(data.plans.map((plan) => plan.id), ['annual', 'monthly']);
          final annual = data.plans.first;
          expect(annual.monthlyPriceLabel, r'$4.17');
          expect(annual.annualTotalLabel, r'$49.99');
          expect(annual.savePercent, 48);
          expect(data.plans.last.monthlyPriceLabel, r'$7.99');
          expect(
            data.features.map((feature) => feature.id),
            ['unlimited', 'sorting', 'sync'],
          );
        },
      );
    });

    test('falls back to the mocked catalog on the Test Store', () async {
      final repository = PaywallRepositoryImpl(
        subscriptionService: _FakeSubscriptions(testStore: true),
      );

      final result = await repository.getPaywallData();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (data) {
          expect(data, PaywallRepositoryImpl.mockedData);
          expect(data.plans.first.monthlyPriceLabel, r'$4.16');
        },
      );
    });

    test('fails when offerings are missing in production', () async {
      final repository = PaywallRepositoryImpl(
        subscriptionService: _FakeSubscriptions(),
      );

      final result = await repository.getPaywallData();

      expect(result.isLeft(), isTrue);
    });

    test('throwing lookup falls back on the Test Store', () async {
      final repository = PaywallRepositoryImpl(
        subscriptionService: _ThrowingSubscriptions(testStore: true),
      );

      final result = await repository.getPaywallData();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (data) => expect(data, PaywallRepositoryImpl.mockedData),
      );
    });

    test('throwing lookup fails in production', () async {
      final repository = PaywallRepositoryImpl(
        subscriptionService: _ThrowingSubscriptions(),
      );

      final result = await repository.getPaywallData();

      expect(result.isLeft(), isTrue);
    });
  });

  group('PaywallRepositoryImpl actions', () {
    test('startTrial succeeds for a plan id', () async {
      final repository = PaywallRepositoryImpl(
        subscriptionService: _FakeSubscriptions(),
      );

      expect((await repository.startTrial(planId: 'annual')).isRight(), isTrue);
    });

    test('startTrial fails for blank plan ids', () async {
      final repository = PaywallRepositoryImpl(
        subscriptionService: _FakeSubscriptions(),
      );

      expect((await repository.startTrial(planId: '')).isLeft(), isTrue);
      expect((await repository.startTrial(planId: '   ')).isLeft(), isTrue);
    });

    test('restorePurchases succeeds', () async {
      final repository = PaywallRepositoryImpl(
        subscriptionService: _FakeSubscriptions(),
      );

      expect((await repository.restorePurchases()).isRight(), isTrue);
    });
  });
}
