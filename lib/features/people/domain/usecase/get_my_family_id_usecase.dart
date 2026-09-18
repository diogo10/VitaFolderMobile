import 'package:fpdart/fpdart.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';

class GetMyFamilyIdUsecase {

  GetMyFamilyIdUsecase({required this.repository});
  final PeopleRepository repository;

  Future<Either<Exception, String?>> call() async {
    return repository.getMyFamilyId();
  }
}
