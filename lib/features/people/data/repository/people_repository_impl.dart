import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/people/data/datasource/people_local_datasource.dart';
import 'package:vita_folder_mobile/features/people/data/models/person_model.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/person_entity.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';

class PeopleRepositoryImpl implements PeopleRepository {
  PeopleLocalDatasource peopleLocalDatasource;
  PeopleRepositoryImpl({required this.peopleLocalDatasource});

  @override
  Future<Either<Failure, List<PersonEntity>>> getPeople() async {
    try {
      final people = await peopleLocalDatasource.getPeople();
      final data = people.map((p) => PersonModel.fromMap(p)).toList();
      return Right(data);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } catch (e) {
      return Left(Failure());
    }
  }
}
