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

class UpdatedReminderSuccess extends CreateReminderState {
  UpdatedReminderSuccess();
}

enum CreateReminderErrorCode { noFamily, authRequired }

class CreateReminderError extends CreateReminderState {
  final String? message;
  final CreateReminderErrorCode? code;
  CreateReminderError({this.message, this.code});
}
