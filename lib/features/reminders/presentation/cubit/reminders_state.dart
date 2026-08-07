import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';

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
  final List<ReminderEntity> reminders;
  final ReminderType? type;
  final bool isLoading;

  LoadedReminders({
    required this.reminders,
    this.type,
    this.isLoading = false,
  });
}

class EmptyReminders extends RemindersState {
  final ReminderType? type;
  final bool isLoading;

  EmptyReminders({this.type, this.isLoading = false});
}

class ReminderError extends RemindersState {
  ReminderError();
}