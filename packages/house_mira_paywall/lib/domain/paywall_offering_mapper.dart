import 'package:house_mira_core/subscriptions/store_package_price.dart';
import 'package:house_mira_paywall/domain/entities/paywall_data.dart';
import 'package:house_mira_paywall/domain/entities/paywall_feature_entity.dart';
import 'package:house_mira_paywall/domain/entities/paywall_plan_entity.dart';
import 'package:intl/intl.dart';

/// Maps live store prices into the paywall catalog.
///
/// Pure so it is unit-testable: [OfferingPrices] carries everything the
/// mapping needs. Feature cards stay static — they are marketing copy
/// resolved via `AppLocalizations` keyed by id, not store data.
///
/// The annual per-month label prefers the store's own
/// `pricePerMonthString` and falls back to formatting `price / 12` in the
/// package currency ([localeName] overrides the ambient locale, mostly for
/// tests). The save badge is derived from the real prices; `null` (no
/// badge) when it cannot be computed or would not be positive.
PaywallData mapOfferingPricesToPaywallData(
  OfferingPrices prices, {
  String? localeName,
}) {
  final monthly = prices.monthly;
  final annual = prices.annual;
  final String locale = localeName ?? Intl.defaultLocale ?? 'en';
  final annualPerMonth =
      annual.pricePerMonthString ??
      NumberFormat.simpleCurrency(
        locale: locale,
        name: annual.currencyCode,
      ).format(annual.price / 12);
  int? savePercent;
  if (monthly.price > 0) {
    final percent = ((1 - annual.price / (monthly.price * 12)) * 100).round();
    if (percent > 0) {
      savePercent = percent;
    }
  }
  return PaywallData(
    plans: [
      PaywallPlanEntity(
        id: 'annual',
        monthlyPriceLabel: annualPerMonth,
        annualTotalLabel: annual.priceString,
        savePercent: savePercent,
      ),
      PaywallPlanEntity(
        id: 'monthly',
        monthlyPriceLabel: monthly.priceString,
      ),
    ],
    features: const [
      PaywallFeatureEntity(id: 'unlimited'),
      PaywallFeatureEntity(id: 'sorting'),
      PaywallFeatureEntity(id: 'sync'),
    ],
  );
}
