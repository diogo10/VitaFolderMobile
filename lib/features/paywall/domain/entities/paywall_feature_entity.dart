import 'package:flutter/foundation.dart';

/// A mocked Pro feature shown on the paywall.
///
/// Display prose is resolved in the view via `AppLocalizations` keyed by
/// [id]; the entity only carries the stable identifier.
@immutable
class PaywallFeatureEntity {
  const PaywallFeatureEntity({required this.id});

  /// Feature identifier: `'unlimited'`, `'sorting'` or `'sync'`.
  final String id;

  PaywallFeatureEntity copyWith({String? id}) {
    return PaywallFeatureEntity(id: id ?? this.id);
  }

  static PaywallFeatureEntity? from(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    if (id is! String) return null;
    return PaywallFeatureEntity(id: id);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PaywallFeatureEntity) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
