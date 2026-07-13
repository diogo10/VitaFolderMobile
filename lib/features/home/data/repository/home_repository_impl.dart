import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/home/domain/entities/home_entity.dart';
import 'package:vita_folder_mobile/features/home/domain/repository/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  @override
  Future<Either<Failure, HomeEntity>> getHomeData() async {
    try {
      final mockData = HomeEntity(
        greeting: 'Good morning!',
        date: 'Monday, July 13',
        message: 'You have 3 tasks remaining today.',
      );
      return Right(mockData);
    } catch (e) {
      return Left(Failure());
    }
  }
}
