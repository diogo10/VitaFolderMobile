import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/features/home/domain/entities/home_entity.dart';
import 'package:vita_folder_mobile/features/home/domain/repository/home_repository.dart';

class GetHomeDataUsecase {
  final HomeRepository repository;

  GetHomeDataUsecase({required this.repository});

  Future<Either<Exception, HomeEntity>> call() async {
    return await repository.getHomeData();
  }
}
