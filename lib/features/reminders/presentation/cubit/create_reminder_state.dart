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
    this.notificationInexact = false,
  });
  final String reminderId;

  /// True when a requested alert will fire (or nothing was requested).
  final bool notificationArmed;

  /// True when a requested one-shot alert was skipped (time already passed).
  final bool notificationTimePassed;

  /// True when the alert is armed but Android may delay it (exact alarms
  /// denied, inexact fallback). The UI warns instead of reporting success.
  final bool notificationInexact;
}

class UpdatedReminderSuccess extends CreateReminderState {
  UpdatedReminderSuccess({
    this.notificationArmed = true,
    this.notificationTimePassed = false,
    this.notificationInexact = false,
  });

  /// True when a requested alert will fire (or nothing was requested).
  final bool notificationArmed;

  /// True when a requested one-shot alert was skipped (time already passed).
  final bool notificationTimePassed;

  /// True when the alert is armed but Android may delay it (exact alarms
  /// denied, inexact fallback). The UI warns instead of reporting success.
  final bool notificationInexact;
}

enum CreateReminderErrorCode { noFamily, authRequired }

class CreateReminderError extends CreateReminderState {
  CreateReminderError({this.message, this.code});
  final String? message;
  final CreateReminderErrorCode? code;
}
