import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';

class JoinFamilyUsecase {
  final PeopleRepository repository;

  JoinFamilyUsecase({required this.repository});

  Future<Either<Exception, bool>> call({required String familyCode}) async {
    // Check if the family code is valid
    if (familyCode.isEmpty || familyCode.length > 6) {
      return Left(Exception('Invalid family code'));
    }
    return repository.joinFamily(inviteCode: familyCode);
  }
}
