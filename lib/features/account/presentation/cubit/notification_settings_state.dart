sealed class NotificationSettingsState {
  NotificationSettingsState();
}

class NotificationSettingsLoading extends NotificationSettingsState {
  NotificationSettingsLoading();
}

enum NotificationPermissionDenied { denied, permanentlyDenied }

class NotificationSettingsLoaded extends NotificationSettingsState {
  final bool notificationsEnabled;
  final bool emailUpdatesEnabled;
  final NotificationPermissionDenied? permissionDenied;

  NotificationSettingsLoaded({
    required this.notificationsEnabled,
    required this.emailUpdatesEnabled,
    this.permissionDenied,
  });
}

class NotificationSettingsError extends NotificationSettingsState {
  NotificationSettingsError();
}
