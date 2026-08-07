sealed class CreateReminderState {
  CreateReminderState();
}

class CreateReminderInitial extends CreateReminderState {
  CreateReminderInitial();
}

class CreateReminderLoading extends CreateReminderState {
  CreateReminderLoading();
}

class CreateReminderSuccess extends CreateReminderState {
  CreateReminderSuccess();
}

class CreateReminderError extends CreateReminderState {
  final String message;
  CreateReminderError({required this.message});
}
