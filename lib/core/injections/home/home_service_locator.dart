import 'package:get_it/get_it.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_cubit.dart';

class HomeServiceLocator {
  final GetIt sl;
  HomeServiceLocator(this.sl);

  void init(AuthService authService) {

    sl.registerSingleton<GetHomeDataUsecase>(
      GetHomeDataUsecase(
        authService: authService,
        peopleRepository: sl(instanceName: 'peopleRepositoryImpl'),
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
