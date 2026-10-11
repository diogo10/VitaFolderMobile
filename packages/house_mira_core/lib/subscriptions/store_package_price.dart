import 'package:meta/meta.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Neutral snapshot of one RevenueCat package's price.
///
/// Decouples feature code from `purchases_flutter` types: the paywall maps
/// these into display entities without importing the store SDK.
@immutable
class StorePackagePrice {
  const StorePackagePrice({
    required this.packageId,
    required this.price,
    required this.priceString,
    required this.currencyCode,
    this.pricePerMonthString,
  });

  /// Builds the snapshot from a RevenueCat package.
  factory StorePackagePrice.fromPackage(Package package) {
    final product = package.storeProduct;
    return StorePackagePrice(
      packageId: package.identifier,
      price: product.price,
      priceString: product.priceString,
      currencyCode: product.currencyCode,
      pricePerMonthString: product.pricePerMonthString,
    );
  }

  /// RevenueCat package identifier (e.g. `$rc_monthly`, `$rc_annual`).
  final String packageId;

  /// Raw price in the local currency (e.g. `49.99`).
  final double price;

  /// Formatted price including its currency sign (e.g. `'$49.99'`).
  final String priceString;

  /// ISO currency code for [price] (e.g. `'USD'`).
  final String currencyCode;

  /// Formatted per-month price for subscriptions, when the store reports
  /// one. `null` for one-time products or stores that omit it (callers
  /// fall back to formatting `price / 12` themselves).
  final String? pricePerMonthString;

  StorePackagePrice copyWith({
    String? packageId,
    double? price,
    String? priceString,
    String? currencyCode,
    String? pricePerMonthString,
  }) {
    return StorePackagePrice(
      packageId: packageId ?? this.packageId,
      price: price ?? this.price,
      priceString: priceString ?? this.priceString,
      currencyCode: currencyCode ?? this.currencyCode,
      pricePerMonthString: pricePerMonthString ?? this.pricePerMonthString,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StorePackagePrice) return false;
    return packageId == other.packageId &&
        price == other.price &&
        priceString == other.priceString &&
        currencyCode == other.currencyCode &&
        pricePerMonthString == other.pricePerMonthString;
  }

  @override
  int get hashCode => Object.hash(
    packageId,
    price,
    priceString,
    currencyCode,
    pricePerMonthString,
  );
}

/// Monthly and annual prices of the current RevenueCat offering.
///
/// `null` (from `SubscriptionService.getOfferingPrices`) means the catalog
/// is unavailable: billing uninitialized, no current offering, a missing
/// package, or a failed lookup.
@immutable
class OfferingPrices {
  const OfferingPrices({required this.monthly, required this.annual});

  final StorePackagePrice monthly;
  final StorePackagePrice annual;

  OfferingPrices copyWith({
    StorePackagePrice? monthly,
    StorePackagePrice? annual,
  }) {
    return OfferingPrices(
      monthly: monthly ?? this.monthly,
      annual: annual ?? this.annual,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OfferingPrices) return false;
    return monthly == other.monthly && annual == other.annual;
  }

  @override
  int get hashCode => Object.hash(monthly, annual);
}
