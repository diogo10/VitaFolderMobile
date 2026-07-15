import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/person_entity.dart';

abstract interface class PeopleRepository {
  Future<Either<Exception, List<PersonEntity>>> getPeople();
}
