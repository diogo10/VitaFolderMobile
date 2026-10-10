sealed class NotificationSettingsState {
  NotificationSettingsState();
}

class NotificationSettingsLoading extends NotificationSettingsState {
  NotificationSettingsLoading();
}

enum NotificationPermissionDenied { denied, permanentlyDenied }

enum NotificationTestResult { sent, failed }

class NotificationSettingsLoaded extends NotificationSettingsState {
  NotificationSettingsLoaded({
    required this.notificationsEnabled,
    this.permissionDenied,
    this.testResult,
  });
  final bool notificationsEnabled;
  final NotificationPermissionDenied? permissionDenied;

  /// Outcome of the last test notification. Null when none was sent (or a
  /// later emit cleared it); the view shows a snackbar only for non-null.
  final NotificationTestResult? testResult;
}

class NotificationSettingsError extends NotificationSettingsState {
  NotificationSettingsError();
}
