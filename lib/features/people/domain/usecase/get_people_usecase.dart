import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/person_entity.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';

class GetPeopleUsecase {
  final PeopleRepository repository;

  GetPeopleUsecase({required this.repository});

  Future<Either<Failure, List<PersonEntity>>> call() async {
    return await repository.getPeople();
  }
}
