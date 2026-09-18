import 'package:fpdart/fpdart.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';

class DeleteFamilyUsecase {

  DeleteFamilyUsecase({required this.repository});
  final PeopleRepository repository;

  Future<Either<Exception, bool>> call({required String familyId}) async {
    return repository.deleteFamily(familyId: familyId);
  }
}
