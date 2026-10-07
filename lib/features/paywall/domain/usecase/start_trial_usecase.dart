import 'package:fpdart/fpdart.dart';
import 'package:house_mira/features/paywall/domain/repository/paywall_repository.dart';

class StartTrialUsecase {
  StartTrialUsecase({required this.repository});
  final PaywallRepository repository;

  Future<Either<Exception, Unit>> call({required String planId}) {
    return repository.startTrial(planId: planId);
  }
}
