import 'package:fpdart/fpdart.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';

class RemoveMemberUsecase {
  final PeopleRepository repository;

  RemoveMemberUsecase({required this.repository});

  Future<Either<Exception, bool>> call({
    required String familyId,
    required String userId,
  }) async {
    return await repository.removeMember(familyId: familyId, userId: userId);
  }
}
