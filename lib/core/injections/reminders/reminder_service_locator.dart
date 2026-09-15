import 'package:get_it/get_it.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/local_storage/local_storage_datasource.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';
import 'package:house_mira/features/reminders/data/repository/reminder_repository_impl.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';
import 'package:house_mira/features/reminders/domain/usecase/create_reminder_usecase.dart';
import 'package:house_mira/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:house_mira/features/reminders/domain/usecase/update_reminder_usecase.dart';
import 'package:house_mira/features/reminders/presentation/cubit/create_reminder_cubit.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_cubit.dart';

class ReminderServiceLocator {
  final GetIt sl;
  ReminderServiceLocator(this.sl);

  void init() {
    sl.registerSingleton<IReminderNotificationService>(
      ReminderNotificationService(
        storage: sl<LocalStorageDatasource>(
          instanceName: 'localStorageDatasource',
        ),
      ),
      instanceName: 'reminderNotificationService',
    );

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

    sl.registerSingleton<UpdateReminderUsecase>(
      UpdateReminderUsecase(
        repository: sl(instanceName: 'reminderRepositoryImpl'),
      ),
      instanceName: 'updateReminderUsecase',
    );

    sl.registerSingleton<RemindersCubit>(
      RemindersCubit(
        getReminderUsecase: sl(instanceName: 'getReminderUsecase'),
        peopleRepository: sl<PeopleRepository>(
          instanceName: 'peopleRepositoryImpl',
        ),
        authService: sl<AuthService>(instanceName: 'authService'),
        reminderRepository: sl(instanceName: 'reminderRepositoryImpl'),
        notificationService: sl(instanceName: 'reminderNotificationService'),
      ),
      instanceName: 'remindersCubit',
    );

    sl.registerSingleton<CreateReminderCubit>(
      CreateReminderCubit(
        createReminderUsecase: sl(instanceName: 'createReminderUsecase'),
        updateReminderUsecase: sl(instanceName: 'updateReminderUsecase'),
        authService: sl<AuthService>(instanceName: 'authService'),
        peopleRepository: sl<PeopleRepository>(
          instanceName: 'peopleRepositoryImpl',
        ),
      ),
      instanceName: 'createReminderCubit',
    );
  }
}
