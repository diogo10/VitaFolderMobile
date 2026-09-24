import 'package:get_it/get_it.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/local_storage/local_storage_datasource.dart';
import 'package:house_mira/core/observability/app_logger.dart';
import 'package:house_mira/core/observability/crash_reporter.dart';
import 'package:house_mira/core/observability/performance_tracer.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';
import 'package:house_mira/features/reminders/data/repository/reminder_repository_impl.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';
import 'package:house_mira/features/reminders/domain/usecase/create_reminder_usecase.dart';
import 'package:house_mira/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:house_mira/features/reminders/domain/usecase/update_reminder_usecase.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_cubit.dart';

class ReminderServiceLocator {
  ReminderServiceLocator(this.sl);
  final GetIt sl;

  void init() {
    final logger = sl.isRegistered<AppLogger>(instanceName: 'appLogger')
        ? sl<AppLogger>(instanceName: 'appLogger')
        : null;
    final tracer =
        sl.isRegistered<PerformanceTracer>(instanceName: 'performanceTracer')
        ? sl<PerformanceTracer>(instanceName: 'performanceTracer')
        : null;
    final crashReporter =
        sl.isRegistered<CrashReporter>(instanceName: 'crashReporter')
        ? sl<CrashReporter>(instanceName: 'crashReporter')
        : null;
    sl
      ..registerSingleton<IReminderNotificationService>(
        ReminderNotificationService(
          storage: sl<LocalStorageDatasource>(
            instanceName: 'localStorageDatasource',
          ),
          logger: logger,
          tracer: tracer,
        ),
        instanceName: 'reminderNotificationService',
      )
      ..registerSingleton<ReminderRepository>(
        ReminderRepositoryImpl(),
        instanceName: 'reminderRepositoryImpl',
      )
      ..registerSingleton<GetReminderUsecase>(
        GetReminderUsecase(
          repository: sl(instanceName: 'reminderRepositoryImpl'),
          peopleRepository: sl<PeopleRepository>(
            instanceName: 'peopleRepositoryImpl',
          ),
        ),
        instanceName: 'getReminderUsecase',
      )
      ..registerSingleton<CreateReminderUsecase>(
        CreateReminderUsecase(
          repository: sl(instanceName: 'reminderRepositoryImpl'),
        ),
        instanceName: 'createReminderUsecase',
      )
      ..registerSingleton<UpdateReminderUsecase>(
        UpdateReminderUsecase(
          repository: sl(instanceName: 'reminderRepositoryImpl'),
        ),
        instanceName: 'updateReminderUsecase',
      )
      // Tab cubits stay shared lazy singletons (see createRouter factory
      // contract). One-shot editor cubits (CreateReminderCubit) are built
      // fresh per visit by the route's default factory, never registered
      // here, so a prior Success/Error cannot leak into the next visit.
      ..registerLazySingleton<RemindersCubit>(
        () => RemindersCubit(
          getReminderUsecase: sl(instanceName: 'getReminderUsecase'),
          peopleRepository: sl<PeopleRepository>(
            instanceName: 'peopleRepositoryImpl',
          ),
          authService: sl<AuthService>(instanceName: 'authService'),
          reminderRepository: sl(instanceName: 'reminderRepositoryImpl'),
          notificationService: sl(instanceName: 'reminderNotificationService'),
          logger: logger,
          crashReporter: crashReporter,
        ),
        instanceName: 'remindersCubit',
      );
  }
}
