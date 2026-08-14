import 'package:get_it/get_it.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:vita_folder_mobile/features/home/domain/usecase/has_reminders_usecase.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_cubit.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';
import 'package:vita_folder_mobile/features/reminders/domain/repository/reminder_repository.dart';

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

    sl.registerSingleton<HasRemindersUsecase>(
      HasRemindersUsecase(
        authService: authService,
        peopleRepository: sl<PeopleRepository>(
          instanceName: 'peopleRepositoryImpl',
        ),
        reminderRepository: sl<ReminderRepository>(
          instanceName: 'reminderRepositoryImpl',
        ),
      ),
      instanceName: 'hasRemindersUsecase',
    );

    sl.registerSingleton<HomeCubit>(
      HomeCubit(
        getHomeDataUsecase: sl(instanceName: 'getHomeDataUsecase'),
        hasRemindersUsecase: sl(instanceName: 'hasRemindersUsecase'),
      ),
      instanceName: 'homeCubit',
    );
  }
}
