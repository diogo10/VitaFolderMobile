import 'package:fpdart/fpdart.dart';
import 'package:house_mira/features/paywall/domain/repository/paywall_repository.dart';

class RestorePurchasesUsecase {
  RestorePurchasesUsecase({required this.repository});
  final PaywallRepository repository;

  Future<Either<Exception, Unit>> call() {
    return repository.restorePurchases();
  }
}
