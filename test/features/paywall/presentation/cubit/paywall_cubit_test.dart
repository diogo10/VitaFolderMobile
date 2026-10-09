import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/subscriptions/subscription_service.dart';
import 'package:house_mira/features/paywall/data/repository/paywall_repository_impl.dart';
import 'package:house_mira/features/paywall/domain/entities/paywall_data.dart';
import 'package:house_mira/features/paywall/domain/entities/paywall_feature_entity.dart';
import 'package:house_mira/features/paywall/domain/entities/paywall_plan_entity.dart';
import 'package:house_mira/features/paywall/domain/repository/paywall_repository.dart';
import 'package:house_mira/features/paywall/domain/usecase/get_paywall_data_usecase.dart';
import 'package:house_mira/features/paywall/domain/usecase/restore_purchases_usecase.dart';
import 'package:house_mira/features/paywall/domain/usecase/start_trial_usecase.dart';
import 'package:house_mira/features/paywall/presentation/cubit/paywall_cubit.dart';
import 'package:house_mira/features/paywall/presentation/cubit/paywall_state.dart';

class _FakePaywallRepository implements PaywallRepository {
  PaywallData data = PaywallRepositoryImpl.mockedData;
  var failData = false;
  var throwData = false;
  var failAction = false;
  var throwAction = false;

  @override
  Future<Either<Exception, PaywallData>> getPaywallData() async {
    if (throwData) throw Exception('boom');
    if (failData) return Left(Exception('offline'));
    return Right(data);
  }

  @override
  Future<Either<Exception, Unit>> startTrial({required String planId}) async {
    if (throwAction) throw Exception('boom');
    if (failAction) return Left(Exception('offline'));
    return const Right(unit);
  }

  @override
  Future<Either<Exception, Unit>> restorePurchases() async {
    if (throwAction) throw Exception('boom');
    if (failAction) return Left(Exception('offline'));
    return const Right(unit);
  }
}

PaywallCubit buildCubit(
  _FakePaywallRepository repository, [
  SubscriptionService? subscriptions,
]) => PaywallCubit(
  getPaywallDataUsecase: GetPaywallDataUsecase(repository: repository),
  startTrialUsecase: StartTrialUsecase(repository: repository),
  restorePurchasesUsecase: RestorePurchasesUsecase(repository: repository),
  subscriptionService: subscriptions,
);

/// Records [invalidateProCache] calls without touching the store.
class _CountingSubscriptions extends SubscriptionService {
  var invalidations = 0;

  @override
  void invalidateProCache() {
    invalidations++;
    super.invalidateProCache();
  }
}

PaywallLoaded loadedWith(_FakePaywallRepository repository, String selected) =>
    PaywallLoaded(data: repository.data, selectedPlanId: selected);

void main() {
  late _FakePaywallRepository repository;

  setUp(() {
    repository = _FakePaywallRepository();
  });

  group('PaywallCubit.loadPaywall', () {
    blocTest<PaywallCubit, PaywallState>(
      'emits Loading then Loaded selecting annual by default',
      build: () => buildCubit(repository),
      act: (cubit) => cubit.loadPaywall(),
      expect: () => [
        const PaywallLoading(),
        PaywallLoaded(data: repository.data, selectedPlanId: 'annual'),
      ],
    );

    blocTest<PaywallCubit, PaywallState>(
      'selects the first plan when no annual plan exists',
      build: () => buildCubit(repository),
      setUp: () {
        repository.data = const PaywallData(
          plans: [
            PaywallPlanEntity(id: 'monthly', monthlyPriceLabel: r'$7.99'),
          ],
          features: [PaywallFeatureEntity(id: 'sync')],
        );
      },
      act: (cubit) => cubit.loadPaywall(),
      expect: () => [
        const PaywallLoading(),
        PaywallLoaded(data: repository.data, selectedPlanId: 'monthly'),
      ],
    );

    blocTest<PaywallCubit, PaywallState>(
      'emits Loading then LoadFailed when the catalog fails',
      build: () => buildCubit(repository),
      setUp: () => repository.failData = true,
      act: (cubit) => cubit.loadPaywall(),
      expect: () => [const PaywallLoading(), const PaywallLoadFailed()],
    );

    blocTest<PaywallCubit, PaywallState>(
      'emits Loading then LoadFailed when the catalog throws',
      build: () => buildCubit(repository),
      setUp: () => repository.throwData = true,
      act: (cubit) => cubit.loadPaywall(),
      expect: () => [const PaywallLoading(), const PaywallLoadFailed()],
    );

    blocTest<PaywallCubit, PaywallState>(
      'emits Loading then LoadFailed when the catalog is empty',
      build: () => buildCubit(repository),
      setUp: () {
        repository.data = const PaywallData(plans: [], features: []);
      },
      act: (cubit) => cubit.loadPaywall(),
      expect: () => [const PaywallLoading(), const PaywallLoadFailed()],
    );
  });

  group('PaywallCubit.selectPlan', () {
    blocTest<PaywallCubit, PaywallState>(
      'updates the selected plan',
      build: () => buildCubit(repository),
      seed: () => loadedWith(repository, 'annual'),
      act: (cubit) => cubit.selectPlan('monthly'),
      expect: () => [loadedWith(repository, 'monthly')],
    );

    blocTest<PaywallCubit, PaywallState>(
      'emits nothing when selecting the current plan',
      build: () => buildCubit(repository),
      seed: () => loadedWith(repository, 'annual'),
      act: (cubit) => cubit.selectPlan('annual'),
      expect: () => <PaywallState>[],
    );

    blocTest<PaywallCubit, PaywallState>(
      'emits nothing before the catalog loads',
      build: () => buildCubit(repository),
      act: (cubit) => cubit.selectPlan('monthly'),
      expect: () => <PaywallState>[],
    );
  });

  group('PaywallCubit.startTrial', () {
    blocTest<PaywallCubit, PaywallState>(
      'emits acting then TrialStarted on success',
      build: () => buildCubit(repository),
      seed: () => loadedWith(repository, 'monthly'),
      act: (cubit) => cubit.startTrial(),
      expect: () => [
        loadedWith(repository, 'monthly').copyWith(isActing: true),
        PaywallTrialStarted(
          data: repository.data,
          selectedPlanId: 'monthly',
          planId: 'monthly',
        ),
      ],
    );

    blocTest<PaywallCubit, PaywallState>(
      'emits acting then ActionFailed on failure',
      build: () => buildCubit(repository),
      seed: () => loadedWith(repository, 'annual'),
      setUp: () => repository.failAction = true,
      act: (cubit) => cubit.startTrial(),
      expect: () => [
        loadedWith(repository, 'annual').copyWith(isActing: true),
        PaywallActionFailed(
          data: repository.data,
          selectedPlanId: 'annual',
        ),
      ],
    );

    blocTest<PaywallCubit, PaywallState>(
      'emits acting then ActionFailed when the call throws',
      build: () => buildCubit(repository),
      seed: () => loadedWith(repository, 'annual'),
      setUp: () => repository.throwAction = true,
      act: (cubit) => cubit.startTrial(),
      expect: () => [
        loadedWith(repository, 'annual').copyWith(isActing: true),
        PaywallActionFailed(
          data: repository.data,
          selectedPlanId: 'annual',
        ),
      ],
    );

    blocTest<PaywallCubit, PaywallState>(
      'emits nothing before the catalog loads',
      build: () => buildCubit(repository),
      act: (cubit) => cubit.startTrial(),
      expect: () => <PaywallState>[],
    );
  });

  group('PaywallCubit.restorePurchases', () {
    blocTest<PaywallCubit, PaywallState>(
      'emits acting then RestoreCompleted on success',
      build: () => buildCubit(repository),
      seed: () => loadedWith(repository, 'annual'),
      act: (cubit) => cubit.restorePurchases(),
      expect: () => [
        loadedWith(repository, 'annual').copyWith(isActing: true),
        PaywallRestoreCompleted(
          data: repository.data,
          selectedPlanId: 'annual',
        ),
      ],
    );

    blocTest<PaywallCubit, PaywallState>(
      'emits acting then ActionFailed on failure',
      build: () => buildCubit(repository),
      seed: () => loadedWith(repository, 'annual'),
      setUp: () => repository.failAction = true,
      act: (cubit) => cubit.restorePurchases(),
      expect: () => [
        loadedWith(repository, 'annual').copyWith(isActing: true),
        PaywallActionFailed(
          data: repository.data,
          selectedPlanId: 'annual',
        ),
      ],
    );

    blocTest<PaywallCubit, PaywallState>(
      'emits acting then ActionFailed when the call throws',
      build: () => buildCubit(repository),
      seed: () => loadedWith(repository, 'annual'),
      setUp: () => repository.throwAction = true,
      act: (cubit) => cubit.restorePurchases(),
      expect: () => [
        loadedWith(repository, 'annual').copyWith(isActing: true),
        PaywallActionFailed(
          data: repository.data,
          selectedPlanId: 'annual',
        ),
      ],
    );

    blocTest<PaywallCubit, PaywallState>(
      'emits nothing before the catalog loads',
      build: () => buildCubit(repository),
      act: (cubit) => cubit.restorePurchases(),
      expect: () => <PaywallState>[],
    );
  });

  group('PaywallCubit entitlement refresh', () {
    test('startTrial success invalidates, failure does not', () async {
      final subscriptions = _CountingSubscriptions();
      var cubit = buildCubit(repository, subscriptions)
        ..emit(loadedWith(repository, 'monthly'));
      addTearDown(cubit.close);
      await cubit.startTrial();
      expect(subscriptions.invalidations, 1);

      repository.failAction = true;
      await cubit.close();
      cubit = buildCubit(repository, subscriptions)
        ..emit(loadedWith(repository, 'monthly'));
      addTearDown(cubit.close);
      await cubit.startTrial();
      expect(subscriptions.invalidations, 1);
    });

    test('restorePurchases success invalidates, failure does not', () async {
      final subscriptions = _CountingSubscriptions();
      var cubit = buildCubit(repository, subscriptions)
        ..emit(loadedWith(repository, 'annual'));
      addTearDown(cubit.close);
      await cubit.restorePurchases();
      expect(subscriptions.invalidations, 1);
      await cubit.close();

      repository.failAction = true;
      cubit = buildCubit(repository, subscriptions)
        ..emit(loadedWith(repository, 'annual'));
      addTearDown(cubit.close);
      await cubit.restorePurchases();
      expect(subscriptions.invalidations, 1);
    });
  });
}
