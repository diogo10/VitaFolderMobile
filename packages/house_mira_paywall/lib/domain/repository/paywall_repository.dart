import 'package:fpdart/fpdart.dart';
import 'package:house_mira_paywall/domain/entities/paywall_data.dart';

/// Paywall catalog source. Today the implementation returns mocked data;
/// real offerings land here when store billing is wired.
abstract class PaywallRepository {
  Future<Either<Exception, PaywallData>> getPaywallData();
  Future<Either<Exception, Unit>> startTrial({required String planId});
  Future<Either<Exception, Unit>> restorePurchases();
}
