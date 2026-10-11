import 'package:fpdart/fpdart.dart';
import 'package:house_mira_core/subscriptions/subscription_service.dart';
import 'package:house_mira_paywall/domain/entities/paywall_data.dart';
import 'package:house_mira_paywall/domain/entities/paywall_feature_entity.dart';
import 'package:house_mira_paywall/domain/entities/paywall_plan_entity.dart';
import 'package:house_mira_paywall/domain/paywall_offering_mapper.dart';
import 'package:house_mira_paywall/domain/repository/paywall_repository.dart';

/// Paywall catalog: live RevenueCat offerings first, mocked data as the
/// Test Store fallback.
///
/// Failure policy (fail-open in dev, fail-closed in prod): when the
/// offerings lookup fails, Test Store builds render the static catalog so
/// development is never blocked, while production builds surface an error
/// so buyers never see fake prices.
class PaywallRepositoryImpl implements PaywallRepository {
  PaywallRepositoryImpl({required SubscriptionService subscriptionService})
    : _subscriptionService = subscriptionService;

  final SubscriptionService _subscriptionService;

  static const mockedData = PaywallData(
    plans: [
      PaywallPlanEntity(
        id: 'annual',
        monthlyPriceLabel: r'$4.16',
        annualTotalLabel: r'$49.99',
        savePercent: 40,
      ),
      PaywallPlanEntity(
        id: 'monthly',
        monthlyPriceLabel: r'$7.99',
      ),
    ],
    features: [
      PaywallFeatureEntity(id: 'unlimited'),
      PaywallFeatureEntity(id: 'sorting'),
      PaywallFeatureEntity(id: 'sync'),
    ],
  );

  @override
  Future<Either<Exception, PaywallData>> getPaywallData() async {
    try {
      final prices = await _subscriptionService.getOfferingPrices();
      if (prices != null) {
        return Right(mapOfferingPricesToPaywallData(prices));
      }
      if (_subscriptionService.isUsingTestStore) {
        return const Right(mockedData);
      }
      return Left(Exception('paywall-unavailable'));
    } on Object catch (_) {
      if (_subscriptionService.isUsingTestStore) {
        return const Right(mockedData);
      }
      return Left(Exception('paywall-unavailable'));
    }
  }

  @override
  Future<Either<Exception, Unit>> startTrial({required String planId}) async {
    if (planId.trim().isEmpty) {
      return Left(Exception('unknown-plan'));
    }
    return const Right(unit);
  }

  @override
  Future<Either<Exception, Unit>> restorePurchases() async {
    return const Right(unit);
  }
}
