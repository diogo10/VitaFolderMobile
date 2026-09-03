import 'package:fpdart/fpdart.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';

class DeleteFamilyUsecase {
  final PeopleRepository repository;

  DeleteFamilyUsecase({required this.repository});

  Future<Either<Exception, bool>> call({required String familyId}) async {
    return await repository.deleteFamily(familyId: familyId);
  }
}
