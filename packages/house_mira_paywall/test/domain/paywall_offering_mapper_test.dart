import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira_core/subscriptions/store_package_price.dart';
import 'package:house_mira_paywall/domain/paywall_offering_mapper.dart';

const _monthly = StorePackagePrice(
  packageId: r'$rc_monthly',
  price: 7.99,
  priceString: r'$7.99',
  currencyCode: 'USD',
  pricePerMonthString: r'$7.99',
);

const _annual = StorePackagePrice(
  packageId: r'$rc_annual',
  price: 49.99,
  priceString: r'$49.99',
  currencyCode: 'USD',
  pricePerMonthString: r'$4.17',
);

void main() {
  group('mapOfferingPricesToPaywallData', () {
    test('maps live prices with the store per-month label', () {
      const prices = OfferingPrices(monthly: _monthly, annual: _annual);

      final data = mapOfferingPricesToPaywallData(prices);

      expect(data.plans.map((plan) => plan.id), ['annual', 'monthly']);
      final annual = data.plans.first;
      expect(annual.monthlyPriceLabel, r'$4.17');
      expect(annual.annualTotalLabel, r'$49.99');
      expect(annual.savePercent, 48);
      final monthly = data.plans.last;
      expect(monthly.monthlyPriceLabel, r'$7.99');
      expect(monthly.annualTotalLabel, isNull);
      expect(monthly.savePercent, isNull);
      expect(
        data.features.map((feature) => feature.id),
        ['unlimited', 'sorting', 'sync'],
      );
    });

    test('formats the per-month label when the store omits it', () {
      const prices = OfferingPrices(
        monthly: _monthly,
        annual: StorePackagePrice(
          packageId: r'$rc_annual',
          price: 49.99,
          priceString: r'$49.99',
          currencyCode: 'USD',
        ),
      );

      final data = mapOfferingPricesToPaywallData(prices, localeName: 'en');

      expect(data.plans.first.monthlyPriceLabel, r'$4.17');
      expect(data.plans.first.savePercent, 48);
    });

    test('omits the badge when the monthly price is free', () {
      const prices = OfferingPrices(
        monthly: StorePackagePrice(
          packageId: r'$rc_monthly',
          price: 0,
          priceString: r'$0.00',
          currencyCode: 'USD',
        ),
        annual: _annual,
      );

      final data = mapOfferingPricesToPaywallData(prices);

      expect(data.plans.first.savePercent, isNull);
      expect(data.plans.first.monthlyPriceLabel, r'$4.17');
      expect(data.plans.last.monthlyPriceLabel, r'$0.00');
    });

    test('omits the badge when the annual plan saves nothing', () {
      const prices = OfferingPrices(
        monthly: StorePackagePrice(
          packageId: r'$rc_monthly',
          price: 1,
          priceString: r'$1.00',
          currencyCode: 'USD',
          pricePerMonthString: r'$1.00',
        ),
        annual: StorePackagePrice(
          packageId: r'$rc_annual',
          price: 99,
          priceString: r'$99.00',
          currencyCode: 'USD',
          pricePerMonthString: r'$8.25',
        ),
      );

      final data = mapOfferingPricesToPaywallData(prices);

      expect(data.plans.first.savePercent, isNull);
    });
  });
}
