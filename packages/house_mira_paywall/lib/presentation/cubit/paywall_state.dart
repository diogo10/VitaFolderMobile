import 'package:house_mira_paywall/domain/entities/paywall_data.dart';

sealed class PaywallState {
  const PaywallState();
}

class PaywallInitial extends PaywallState {
  const PaywallInitial();
}

class PaywallLoading extends PaywallState {
  const PaywallLoading();
}

/// Catalog ready. Also carries the transient `isActing` flag while a
/// mocked trial/restore call is in flight so the CTA shows its loader.
class PaywallLoaded extends PaywallState {
  const PaywallLoaded({
    required this.data,
    required this.selectedPlanId,
    this.isActing = false,
  });

  final PaywallData data;
  final String selectedPlanId;
  final bool isActing;

  PaywallLoaded copyWith({
    PaywallData? data,
    String? selectedPlanId,
    bool? isActing,
  }) {
    return PaywallLoaded(
      data: data ?? this.data,
      selectedPlanId: selectedPlanId ?? this.selectedPlanId,
      isActing: isActing ?? this.isActing,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other.runtimeType == runtimeType &&
        other is PaywallLoaded &&
        data == other.data &&
        selectedPlanId == other.selectedPlanId &&
        isActing == other.isActing;
  }

  @override
  int get hashCode => Object.hash(runtimeType, data, selectedPlanId, isActing);
}

class PaywallLoadFailed extends PaywallState {
  const PaywallLoadFailed();
}

/// Mocked trial started for [planId]. Extends [PaywallLoaded] so the
/// builder keeps rendering the catalog underneath the snackbar.
class PaywallTrialStarted extends PaywallLoaded {
  const PaywallTrialStarted({
    required super.data,
    required super.selectedPlanId,
    required this.planId,
  });

  final String planId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaywallTrialStarted &&
        data == other.data &&
        selectedPlanId == other.selectedPlanId &&
        planId == other.planId;
  }

  @override
  int get hashCode => Object.hash(data, selectedPlanId, planId);
}

/// Mocked restore completed. Extends [PaywallLoaded] so the builder keeps
/// rendering the catalog underneath the snackbar.
class PaywallRestoreCompleted extends PaywallLoaded {
  const PaywallRestoreCompleted({
    required super.data,
    required super.selectedPlanId,
  });
}

/// Mocked trial/restore call failed. Extends [PaywallLoaded] so the
/// builder keeps rendering the catalog underneath the snackbar.
class PaywallActionFailed extends PaywallLoaded {
  const PaywallActionFailed({
    required super.data,
    required super.selectedPlanId,
  });
}
