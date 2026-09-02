import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_view_mode.dart';

sealed class RemindersState {
  final RemindersViewMode viewMode;
  final Set<ReminderType> filterTypes;
  RemindersState({
    this.viewMode = RemindersViewMode.list,
    this.filterTypes = const {},
  });
}

class ReminderInitialState extends RemindersState {
  ReminderInitialState({super.viewMode, super.filterTypes});
}

class RemindersLoading extends RemindersState {
  RemindersLoading({super.viewMode, super.filterTypes});
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
    super.filterTypes,
  });
}

class EmptyReminders extends RemindersState {
  final ReminderType? type;
  final bool isLoading;

  EmptyReminders({
    this.type,
    this.isLoading = false,
    super.viewMode,
    super.filterTypes,
  });
}

class ReminderError extends RemindersState {
  ReminderError({super.viewMode, super.filterTypes});
}
