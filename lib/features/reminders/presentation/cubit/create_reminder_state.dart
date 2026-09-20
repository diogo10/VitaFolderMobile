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
  CreateReminderSuccess({
    required this.reminderId,
    this.notificationArmed = true,
    this.notificationTimePassed = false,
  });
  final String reminderId;

  /// True when a requested alert will fire (or nothing was requested).
  final bool notificationArmed;

  /// True when a requested one-shot alert was skipped (time already passed).
  final bool notificationTimePassed;
}

class UpdatedReminderSuccess extends CreateReminderState {
  UpdatedReminderSuccess({
    this.notificationArmed = true,
    this.notificationTimePassed = false,
  });

  /// True when a requested alert will fire (or nothing was requested).
  final bool notificationArmed;

  /// True when a requested one-shot alert was skipped (time already passed).
  final bool notificationTimePassed;
}

enum CreateReminderErrorCode { noFamily, authRequired }

class CreateReminderError extends CreateReminderState {
  CreateReminderError({this.message, this.code});
  final String? message;
  final CreateReminderErrorCode? code;
}
