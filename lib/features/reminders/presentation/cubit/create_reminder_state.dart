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

  CreateReminderSuccess({required this.reminderId});
  final String reminderId;
}

class UpdatedReminderSuccess extends CreateReminderState {
  UpdatedReminderSuccess();
}

enum CreateReminderErrorCode { noFamily, authRequired }

class CreateReminderError extends CreateReminderState {
  CreateReminderError({this.message, this.code});
  final String? message;
  final CreateReminderErrorCode? code;
}
