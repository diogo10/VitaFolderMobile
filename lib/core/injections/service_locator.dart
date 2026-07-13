import 'package:get_it/get_it.dart';
import 'package:vita_folder_mobile/core/injections/home/home_service_locator.dart';
import 'package:vita_folder_mobile/core/injections/reminders/reminder_service_locator.dart';

final GetIt slInstance = GetIt.instance;

class ServiceLocator {
  Future<void> init() async {
    final reminderServiceLocator = ReminderServiceLocator(slInstance);
    reminderServiceLocator.init();

    final homeServiceLocator = HomeServiceLocator(slInstance);
    homeServiceLocator.init();
  }
}
