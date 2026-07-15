import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/people/data/datasource/people_local_datasource.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/person_entity.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';

class PeopleRepositoryImpl implements PeopleRepository {
  PeopleLocalDatasource peopleLocalDatasource;
  PeopleRepositoryImpl({required this.peopleLocalDatasource});

  @override
  Future<Either<Exception, List<PersonEntity>>> getPeople() async {
    return Left(NoDataException());
  }
}
