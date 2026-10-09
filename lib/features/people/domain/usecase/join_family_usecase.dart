import 'package:fpdart/fpdart.dart';
import 'package:house_mira/features/people/domain/invite_code.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';

class JoinFamilyUsecase {
  JoinFamilyUsecase({required this.repository});
  final PeopleRepository repository;

  Future<Either<Exception, bool>> call({required String familyCode}) async {
    final normalized = normalizeInviteCode(familyCode);
    if (!isValidInviteCode(normalized)) {
      return Left(Exception('Invalid family code'));
    }
    return repository.joinFamily(inviteCode: normalized);
  }
}
