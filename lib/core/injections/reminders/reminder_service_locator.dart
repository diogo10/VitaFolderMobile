import 'package:get_it/get_it.dart';
import 'package:vita_folder_mobile/features/reminders/data/datasource/reminder_remote_datasource.dart';
import 'package:vita_folder_mobile/features/reminders/data/repository/reminder_repository_impl.dart';
import 'package:vita_folder_mobile/features/reminders/domain/repository/reminder_repository.dart';
import 'package:vita_folder_mobile/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';

class ReminderServiceLocator {
  final GetIt sl;
  ReminderServiceLocator(this.sl);

  void init() {
    sl.registerSingleton<ReminderRemoteDatasource>(
      ReminderRemoteDatasource(),
      instanceName: 'reminderRemoteDatasource',
    );

    sl.registerSingleton<ReminderRepository>(
      ReminderRepositoryImpl(
        reminderRemoteDatasource: sl(instanceName: 'reminderRemoteDatasource'),
      ),
      instanceName: 'reminderRepositoryImpl',
    );

    sl.registerSingleton<GetReminderUsecase>(
      GetReminderUsecase(
        repository: sl(instanceName: 'reminderRepositoryImpl'),
      ),
      instanceName: 'getReminderUsecase',
    );

    sl.registerSingleton<RemindersCubit>(
      RemindersCubit(
        getReminderUsecase: sl(instanceName: 'getReminderUsecase'),
      ),
      instanceName: 'remindersCubit',
    );
  }
}
