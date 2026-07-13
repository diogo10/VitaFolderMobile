import 'package:get_it/get_it.dart';
import 'package:vita_folder_mobile/features/home/data/repository/home_repository_impl.dart';
import 'package:vita_folder_mobile/features/home/domain/repository/home_repository.dart';
import 'package:vita_folder_mobile/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_cubit.dart';

class HomeServiceLocator {
  final GetIt sl;
  HomeServiceLocator(this.sl);

  void init() {
    sl.registerSingleton<HomeRepository>(
      HomeRepositoryImpl(),
      instanceName: 'homeRepositoryImpl',
    );

    sl.registerSingleton<GetHomeDataUsecase>(
      GetHomeDataUsecase(
        repository: sl(instanceName: 'homeRepositoryImpl'),
      ),
      instanceName: 'getHomeDataUsecase',
    );

    sl.registerSingleton<HomeCubit>(
      HomeCubit(
        getHomeDataUsecase: sl(instanceName: 'getHomeDataUsecase'),
      ),
      instanceName: 'homeCubit',
    );
  }
}
