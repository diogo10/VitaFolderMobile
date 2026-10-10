import 'package:house_mira_paywall/domain/entities/paywall_feature_entity.dart';
import 'package:house_mira_paywall/domain/entities/paywall_plan_entity.dart';
import 'package:meta/meta.dart';

/// Mocked paywall catalog: the plans and features shown on the screen.
@immutable
class PaywallData {
  const PaywallData({required this.plans, required this.features});

  final List<PaywallPlanEntity> plans;
  final List<PaywallFeatureEntity> features;

  PaywallData copyWith({
    List<PaywallPlanEntity>? plans,
    List<PaywallFeatureEntity>? features,
  }) {
    return PaywallData(
      plans: plans ?? this.plans,
      features: features ?? this.features,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PaywallData) return false;
    return _listEquals(plans, other.plans) &&
        _listEquals(features, other.features);
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(plans), Object.hashAll(features));

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
