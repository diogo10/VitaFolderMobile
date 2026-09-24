import 'package:get_it/get_it.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:house_mira/features/home/domain/usecase/has_reminders_usecase.dart';
import 'package:house_mira/features/home/presentation/cubit/home_cubit.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';

class HomeServiceLocator {
  HomeServiceLocator(this.sl);
  final GetIt sl;

  void init(AuthService authService) {
    sl
      ..registerSingleton<GetHomeDataUsecase>(
        GetHomeDataUsecase(
          authService: authService,
          peopleRepository: sl(instanceName: 'peopleRepositoryImpl'),
          reminderRepository: sl<ReminderRepository>(
            instanceName: 'reminderRepositoryImpl',
          ),
        ),
        instanceName: 'getHomeDataUsecase',
      )
      ..registerSingleton<HasRemindersUsecase>(
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
      )
      ..registerLazySingleton<HomeCubit>(
        () => HomeCubit(
          getHomeDataUsecase: sl(instanceName: 'getHomeDataUsecase'),
          hasRemindersUsecase: sl(instanceName: 'hasRemindersUsecase'),
        ),
        instanceName: 'homeCubit',
      );
  }
}
