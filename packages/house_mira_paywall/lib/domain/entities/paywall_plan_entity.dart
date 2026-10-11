import 'package:meta/meta.dart';

/// A mocked subscription plan shown on the paywall.
///
/// Display prose (titles, notes) is resolved in the view via
/// `AppLocalizations` keyed by [id]; only the mocked price labels live
/// here so the same entity works across locales.
@immutable
class PaywallPlanEntity {
  const PaywallPlanEntity({
    required this.id,
    required this.monthlyPriceLabel,
    this.annualTotalLabel,
    this.savePercent,
  });

  /// Plan identifier: `'annual'` or `'monthly'`.
  final String id;

  /// Mocked per-month price label (e.g. `'$4.16'`).
  final String monthlyPriceLabel;

  /// Mocked yearly total label for annual billing (e.g. `'$49.99'`).
  /// `null` for plans without yearly billing.
  final String? annualTotalLabel;

  /// Mocked discount percent shown as a badge (e.g. `40`).
  /// `null` when the plan carries no badge.
  final int? savePercent;

  bool get isAnnual => id == 'annual';

  PaywallPlanEntity copyWith({
    String? id,
    String? monthlyPriceLabel,
    String? annualTotalLabel,
    int? savePercent,
  }) {
    return PaywallPlanEntity(
      id: id ?? this.id,
      monthlyPriceLabel: monthlyPriceLabel ?? this.monthlyPriceLabel,
      annualTotalLabel: annualTotalLabel ?? this.annualTotalLabel,
      savePercent: savePercent ?? this.savePercent,
    );
  }

  static PaywallPlanEntity? from(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    final monthlyPriceLabel = json['monthlyPriceLabel'];
    if (id is! String || monthlyPriceLabel is! String) return null;
    final annualTotalLabel = json['annualTotalLabel'];
    final savePercent = json['savePercent'];
    return PaywallPlanEntity(
      id: id,
      monthlyPriceLabel: monthlyPriceLabel,
      annualTotalLabel: annualTotalLabel is String ? annualTotalLabel : null,
      savePercent: savePercent is int ? savePercent : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PaywallPlanEntity) return false;
    return id == other.id &&
        monthlyPriceLabel == other.monthlyPriceLabel &&
        annualTotalLabel == other.annualTotalLabel &&
        savePercent == other.savePercent;
  }

  @override
  int get hashCode =>
      Object.hash(id, monthlyPriceLabel, annualTotalLabel, savePercent);
}
