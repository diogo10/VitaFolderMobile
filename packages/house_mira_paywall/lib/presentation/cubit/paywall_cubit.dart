import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira_core/subscriptions/subscription_service.dart';
import 'package:house_mira_paywall/domain/usecase/get_paywall_data_usecase.dart';
import 'package:house_mira_paywall/domain/usecase/restore_purchases_usecase.dart';
import 'package:house_mira_paywall/domain/usecase/start_trial_usecase.dart';
import 'package:house_mira_paywall/presentation/cubit/paywall_state.dart';

/// Paywall presentation state. The catalog is mocked until store billing
/// is wired; actions surface a snackbar via one-shot outcome states.
class PaywallCubit extends Cubit<PaywallState> {
  PaywallCubit({
    required GetPaywallDataUsecase getPaywallDataUsecase,
    required StartTrialUsecase startTrialUsecase,
    required RestorePurchasesUsecase restorePurchasesUsecase,
    required SubscriptionService subscriptionService,
  }) : _getPaywallDataUsecase = getPaywallDataUsecase,
       _startTrialUsecase = startTrialUsecase,
       _restorePurchasesUsecase = restorePurchasesUsecase,
       _subscriptionService = subscriptionService,
       super(const PaywallInitial());

  final GetPaywallDataUsecase _getPaywallDataUsecase;
  final StartTrialUsecase _startTrialUsecase;
  final RestorePurchasesUsecase _restorePurchasesUsecase;

  /// Refreshes the cached entitlement after purchase/restore so the next
  /// limit check sees the new status immediately instead of the stale
  /// 30s cache. Required: the locator always provides the shared service
  /// and tests pass a fake.
  final SubscriptionService _subscriptionService;

  Future<void> loadPaywall() async {
    emit(const PaywallLoading());
    try {
      final result = await _getPaywallDataUsecase();
      result.fold(
        (_) => emit(const PaywallLoadFailed()),
        (data) {
          // Never render an empty catalog: explicit failure beats a
          // plan list with no selectable plan.
          if (data.plans.isEmpty) {
            emit(const PaywallLoadFailed());
            return;
          }
          final selected = data.plans
              .firstWhere(
                (plan) => plan.isAnnual,
                orElse: () => data.plans.first,
              )
              .id;
          emit(
            PaywallLoaded(data: data, selectedPlanId: selected),
          );
        },
      );
    } on Object catch (_) {
      emit(const PaywallLoadFailed());
    }
  }

  /// Synchronous selection update; no backend call behind it.
  void selectPlan(String planId) {
    if (state is PaywallLoaded) {
      final current = state as PaywallLoaded;
      if (current.selectedPlanId == planId) return;
      emit(current.copyWith(selectedPlanId: planId, isActing: false));
    }
  }

  Future<void> startTrial() async {
    if (state is! PaywallLoaded) return;
    final current = state as PaywallLoaded;
    emit(current.copyWith(isActing: true));
    try {
      final result = await _startTrialUsecase(planId: current.selectedPlanId);
      result.fold(
        (_) => emit(
          PaywallActionFailed(
            data: current.data,
            selectedPlanId: current.selectedPlanId,
          ),
        ),
        (_) {
          _subscriptionService.invalidateProCache();
          emit(
            PaywallTrialStarted(
              data: current.data,
              selectedPlanId: current.selectedPlanId,
              planId: current.selectedPlanId,
            ),
          );
        },
      );
    } on Object catch (_) {
      emit(
        PaywallActionFailed(
          data: current.data,
          selectedPlanId: current.selectedPlanId,
        ),
      );
    }
  }

  Future<void> restorePurchases() async {
    if (state is! PaywallLoaded) return;
    final current = state as PaywallLoaded;
    emit(current.copyWith(isActing: true));
    try {
      final result = await _restorePurchasesUsecase();
      result.fold(
        (_) => emit(
          PaywallActionFailed(
            data: current.data,
            selectedPlanId: current.selectedPlanId,
          ),
        ),
        (_) {
          _subscriptionService.invalidateProCache();
          emit(
            PaywallRestoreCompleted(
              data: current.data,
              selectedPlanId: current.selectedPlanId,
            ),
          );
        },
      );
    } on Object catch (_) {
      emit(
        PaywallActionFailed(
          data: current.data,
          selectedPlanId: current.selectedPlanId,
        ),
      );
    }
  }
}
