import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/person_entity.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/family_entity.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/people_data.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';

class GetPeopleUsecase {
  final PeopleRepository repository;

  GetPeopleUsecase({required this.repository});

  Future<Either<Exception, PeopleData>> call() async {
    final peopleResult = await repository.getPeople();
    final familyResult = await repository.getFamily();
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
