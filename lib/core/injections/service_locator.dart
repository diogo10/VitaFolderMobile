import 'package:get_it/get_it.dart';
import 'package:vita_folder_mobile/core/injections/home/home_service_locator.dart';
import 'package:vita_folder_mobile/core/injections/people/people_service_locator.dart';
import 'package:vita_folder_mobile/core/injections/reminders/reminder_service_locator.dart';
import 'package:vita_folder_mobile/features/onboarding/data/datasource/onboarding_local_datasource.dart';

final GetIt slInstance = GetIt.instance;

class ServiceLocator {
  Future<void> init() async {
    slInstance.registerSingleton<OnboardingLocalDatasource>(
      OnboardingLocalDatasource(),
      instanceName: 'onboardingLocalDatasource',
    );

    final reminderServiceLocator = ReminderServiceLocator(slInstance);
    reminderServiceLocator.init();

    final homeServiceLocator = HomeServiceLocator(slInstance);
    homeServiceLocator.init();

    final peopleServiceLocator = PeopleServiceLocator(slInstance);
    peopleServiceLocator.init();
  }
}
