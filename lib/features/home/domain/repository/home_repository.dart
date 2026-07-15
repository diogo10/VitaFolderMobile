import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/features/home/domain/entities/home_entity.dart';

abstract interface class HomeRepository {
  Future<Either<Exception, HomeEntity>> getHomeData();
}
