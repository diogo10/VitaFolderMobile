import 'package:get_it/get_it.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/local_storage/local_storage_datasource.dart';
import 'package:house_mira/features/account/application/notification_permission_service.dart';
import 'package:house_mira/features/account/presentation/cubit/account_cubit.dart';
import 'package:house_mira/features/account/presentation/cubit/manage_profile_cubit.dart';
import 'package:house_mira/features/account/presentation/cubit/notification_settings_cubit.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';

class AccountServiceLocator {
  AccountServiceLocator(this.sl);
  final GetIt sl;

  void init() {
    sl
      ..registerSingleton<AccountCubit>(
        AccountCubit(
          authService: sl<AuthService>(instanceName: 'authService'),
          peopleRepository: sl<PeopleRepository>(
            instanceName: 'peopleRepositoryImpl',
          ),
        ),
        instanceName: 'accountCubit',
      )
      ..registerSingleton<ManageProfileCubit>(
        ManageProfileCubit(
          authService: sl<AuthService>(instanceName: 'authService'),
        ),
        instanceName: 'manageProfileCubit',
      )
      ..registerSingleton<NotificationSettingsCubit>(
        NotificationSettingsCubit(
          permissionService: NotificationPermissionService(),
          storage: sl<LocalStorageDatasource>(
            instanceName: 'localStorageDatasource',
          ),
          notificationService: sl(instanceName: 'reminderNotificationService'),
        ),
        instanceName: 'notificationSettingsCubit',
      );
  }
}
