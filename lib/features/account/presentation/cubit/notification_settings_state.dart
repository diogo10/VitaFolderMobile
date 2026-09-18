sealed class NotificationSettingsState {
  NotificationSettingsState();
}

class NotificationSettingsLoading extends NotificationSettingsState {
  NotificationSettingsLoading();
}

enum NotificationPermissionDenied { denied, permanentlyDenied }

class NotificationSettingsLoaded extends NotificationSettingsState {

  NotificationSettingsLoaded({
    required this.notificationsEnabled,
    this.permissionDenied,
  });
  final bool notificationsEnabled;
  final NotificationPermissionDenied? permissionDenied;
}

class NotificationSettingsError extends NotificationSettingsState {
  NotificationSettingsError();
}
