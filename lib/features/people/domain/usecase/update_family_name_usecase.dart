import 'package:fpdart/fpdart.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';

class UpdateFamilyNameUsecase {
  final PeopleRepository repository;

  UpdateFamilyNameUsecase({required this.repository});

  Future<Either<Exception, bool>> call({
    required String familyId,
    required String name,
  }) async {
    return await repository.updateFamilyName(familyId: familyId, name: name);
  }
}
