import 'package:fpdart/fpdart.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';

class UpdateFamilyNameUsecase {

  UpdateFamilyNameUsecase({required this.repository});
  final PeopleRepository repository;

  Future<Either<Exception, bool>> call({
    required String familyId,
    required String name,
  }) async {
    return repository.updateFamilyName(familyId: familyId, name: name);
  }
}
