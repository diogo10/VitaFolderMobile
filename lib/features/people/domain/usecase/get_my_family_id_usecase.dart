import 'package:fpdart/fpdart.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';

class GetMyFamilyIdUsecase {
  final PeopleRepository repository;

  GetMyFamilyIdUsecase({required this.repository});

  Future<Either<Exception, String?>> call() async {
    return await repository.getMyFamilyId();
  }
}
