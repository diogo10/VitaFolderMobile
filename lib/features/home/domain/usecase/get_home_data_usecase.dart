import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';
import 'package:vita_folder_mobile/features/home/domain/entities/home_entity.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/person_entity.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';

class GetHomeDataUsecase {
  final PeopleRepository peopleRepository;
  final AuthService authService;

  GetHomeDataUsecase({
    required this.peopleRepository,
    required this.authService,
  });

  Future<Either<Exception, HomeEntity>> call() async {
     if (!authService.isLoggedIn()) {
      return Left(NoDataException());
    }

    final peopleResult = await peopleRepository.getPeople();
    final people = peopleResult.getRight().getOrElse(() => <PersonEntity>[]);

    return Right(HomeEntity(
      greeting: "Hello",
      date: DateTime.now().toIso8601String(),
      message: "You have ${people.length} people in your circle.",
      peopleInCircle: people,
    ));
  }
}
