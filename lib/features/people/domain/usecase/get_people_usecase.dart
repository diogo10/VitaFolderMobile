import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/person_entity.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';

class GetPeopleUsecase {
  final PeopleRepository repository;

  GetPeopleUsecase({required this.repository});

  Future<Either<Exception, List<PersonEntity>>> call() async {
    final result =  await repository.getPeople();
    if (result.isLeft()) {
      return Right(List.empty());
    }
    return result;
  }
}
