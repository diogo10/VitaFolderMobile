import 'package:fpdart/fpdart.dart';
import 'package:house_mira_paywall/domain/entities/paywall_data.dart';
import 'package:house_mira_paywall/domain/repository/paywall_repository.dart';

class GetPaywallDataUsecase {
  GetPaywallDataUsecase({required this.repository});
  final PaywallRepository repository;

  Future<Either<Exception, PaywallData>> call() {
    return repository.getPaywallData();
  }
}
