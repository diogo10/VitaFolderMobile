import 'package:fpdart/fpdart.dart';
import 'package:house_mira_paywall/domain/entities/paywall_data.dart';

/// Paywall catalog source: live RevenueCat offerings, with the mocked
/// catalog as the Test Store fallback.
abstract class PaywallRepository {
  Future<Either<Exception, PaywallData>> getPaywallData();
  Future<Either<Exception, Unit>> startTrial({required String planId});
  Future<Either<Exception, Unit>> restorePurchases();
}
