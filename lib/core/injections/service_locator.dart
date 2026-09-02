import 'package:get_it/get_it.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/functions/edget_functions.dart';
import 'package:house_mira/core/injections/account/account_service_locator.dart';
import 'package:house_mira/core/injections/home/home_service_locator.dart';
import 'package:house_mira/core/injections/people/people_service_locator.dart';
import 'package:house_mira/core/injections/reminders/reminder_service_locator.dart';
import 'package:house_mira/core/local_storage/local_storage_datasource.dart';
import 'package:house_mira/features/onboarding/data/datasource/onboarding_local_datasource.dart';

final GetIt slInstance = GetIt.instance;

class ServiceLocator {
  Future<void> init() async {
    slInstance.registerSingleton<AuthService>(
      AuthService(),
      instanceName: 'authService',
    );

    slInstance.registerSingleton<EdgetFunctions>(
      EdgetFunctions(),
      instanceName: 'edgetFunctions',
    );

    slInstance.registerSingleton<OnboardingLocalDatasource>(
      OnboardingLocalDatasource(),
      instanceName: 'onboardingLocalDatasource',
    );

    slInstance.registerSingleton<LocalStorageDatasource>(
      LocalStorageDatasource(),
      instanceName: 'localStorageDatasource',
    );

    final peopleServiceLocator = PeopleServiceLocator(slInstance);
    peopleServiceLocator.init();

    final reminderServiceLocator = ReminderServiceLocator(slInstance);
    reminderServiceLocator.init();

    final homeServiceLocator = HomeServiceLocator(slInstance);
    homeServiceLocator.init(slInstance(instanceName: 'authService'));

    final accountServiceLocator = AccountServiceLocator(slInstance);
    accountServiceLocator.init();
  }
}