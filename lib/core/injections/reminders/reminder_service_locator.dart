import 'package:get_it/get_it.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';
import 'package:vita_folder_mobile/features/reminders/data/repository/reminder_repository_impl.dart';
import 'package:vita_folder_mobile/features/reminders/domain/repository/reminder_repository.dart';
import 'package:vita_folder_mobile/features/reminders/domain/usecase/create_reminder_usecase.dart';
import 'package:vita_folder_mobile/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/create_reminder_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';

class ReminderServiceLocator {
  final GetIt sl;
  ReminderServiceLocator(this.sl);

  void init() {
    sl.registerSingleton<ReminderRepository>(
      ReminderRepositoryImpl(),
      instanceName: 'reminderRepositoryImpl',
    );

    sl.registerSingleton<GetReminderUsecase>(
      GetReminderUsecase(
        repository: sl(instanceName: 'reminderRepositoryImpl'),
        peopleRepository: sl<PeopleRepository>(
          instanceName: 'peopleRepositoryImpl',
        ),
      ),
      instanceName: 'getReminderUsecase',
    );

    sl.registerSingleton<CreateReminderUsecase>(
      CreateReminderUsecase(
        repository: sl(instanceName: 'reminderRepositoryImpl'),
      ),
      instanceName: 'createReminderUsecase',
    );

    sl.registerSingleton<RemindersCubit>(
      RemindersCubit(
        getReminderUsecase: sl(instanceName: 'getReminderUsecase'),
        peopleRepository: sl<PeopleRepository>(
          instanceName: 'peopleRepositoryImpl',
        ),
        authService: sl<AuthService>(instanceName: 'authService'),
        reminderRepository: sl(instanceName: 'reminderRepositoryImpl'),
      ),
      instanceName: 'remindersCubit',
    );

    sl.registerSingleton<CreateReminderCubit>(
      CreateReminderCubit(
        createReminderUsecase: sl(instanceName: 'createReminderUsecase'),
        authService: sl<AuthService>(instanceName: 'authService'),
        peopleRepository: sl<PeopleRepository>(
          instanceName: 'peopleRepositoryImpl',
        ),
      ),
      instanceName: 'createReminderCubit',
    );
  }
}
