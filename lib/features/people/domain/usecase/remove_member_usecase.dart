import 'package:fpdart/fpdart.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';

class RemoveMemberUsecase {

  RemoveMemberUsecase({required this.repository});
  final PeopleRepository repository;

  Future<Either<Exception, bool>> call({
    required String familyId,
    required String userId,
  }) async {
    return repository.removeMember(familyId: familyId, userId: userId);
  }
}
