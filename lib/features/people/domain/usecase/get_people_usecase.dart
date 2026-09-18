import 'package:fpdart/fpdart.dart';
import 'package:house_mira/features/people/domain/entities/family_entity.dart';
import 'package:house_mira/features/people/domain/entities/people_data.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';

class GetPeopleUsecase {

  GetPeopleUsecase({required this.repository});
  final PeopleRepository repository;

  Future<Either<Exception, PeopleData>> call() async {
    final peopleResult = await repository.getPeople();
    final familyResult = await repository.getMyFamily();
    final people = peopleResult.getOrElse((_) => <PersonEntity>[]);

    return Right(
      PeopleData(
        family: familyResult.getOrElse(
          (_) => FamilyEntity(name: '', inviteCode: ''),
        ),
        people: people,
      ),
    );
  }
}
