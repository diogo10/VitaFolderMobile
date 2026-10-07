import 'package:fpdart/fpdart.dart';
import 'package:house_mira/features/paywall/domain/entities/paywall_data.dart';
import 'package:house_mira/features/paywall/domain/entities/paywall_feature_entity.dart';
import 'package:house_mira/features/paywall/domain/entities/paywall_plan_entity.dart';
import 'package:house_mira/features/paywall/domain/repository/paywall_repository.dart';

/// Mocked paywall catalog. Returns the static plans and features from the
/// design until real store offerings are wired through [SubscriptionService].
class PaywallRepositoryImpl implements PaywallRepository {
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
    return const Right(mockedData);
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
