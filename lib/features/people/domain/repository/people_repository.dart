import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/family_entity.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/person_entity.dart';

abstract interface class PeopleRepository {
  Future<Either<Exception, List<PersonEntity>>> getPeople();
  Future<Either<Exception, bool>> createFamily({required String name, required String inviteCode});
  Future<Either<Exception, bool>> joinFamily({required String inviteCode});
  Future<Either<Exception, FamilyEntity>> getMyFamily();
  Future<FamilyEntity?> getFamilyBy(String id);
  Future<List<String>> getFamilyIdsForUser(String userId);
  Future<List<PersonEntity>> getProfilesWithRoleForFamily(String familyId);
}
