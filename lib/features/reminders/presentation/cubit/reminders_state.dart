import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';

sealed class RemindersState {
  RemindersState();
}

class ReminderInitialState extends RemindersState {
  ReminderInitialState();
}

class RemindersLoading extends RemindersState {
  RemindersLoading();
}

class LoadedReminders extends RemindersState {
  List<ReminderEntity> reminders;
  LoadedReminders({required this.reminders});
}

class EmptyReminders extends RemindersState {
  EmptyReminders();
}

class ReminderError extends RemindersState {
  ReminderError();
}
