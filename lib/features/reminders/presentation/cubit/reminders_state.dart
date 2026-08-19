import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_view_mode.dart';

sealed class RemindersState {
  final RemindersViewMode viewMode;
  RemindersState({this.viewMode = RemindersViewMode.list});
}

class ReminderInitialState extends RemindersState {
  ReminderInitialState({super.viewMode});
}

class RemindersLoading extends RemindersState {
  RemindersLoading({super.viewMode});
}

class LoadedReminders extends RemindersState {
  final List<ReminderEntity> reminders;
  final ReminderType? type;
  final bool isLoading;

  LoadedReminders({
    required this.reminders,
    this.type,
    this.isLoading = false,
    super.viewMode,
  });
}

class EmptyReminders extends RemindersState {
  final ReminderType? type;
  final bool isLoading;

  EmptyReminders({this.type, this.isLoading = false, super.viewMode});
}

class ReminderError extends RemindersState {
  ReminderError({super.viewMode});
}
