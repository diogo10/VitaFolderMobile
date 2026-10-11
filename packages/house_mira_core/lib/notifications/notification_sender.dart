/// Minimal notification-sending contract owned by core.
///
/// Feature packages that only need to post a test/delivery notification
/// (e.g. account settings) depend on this — never on another feature's
/// application layer. The reminders package implements this interface
/// alongside its richer [IReminderNotificationService]-equivalent API.
abstract interface class NotificationSender {
  /// Shows an immediate test notification. Returns true when posted,
  /// false otherwise (never throws).
  Future<bool> showTestNotification({
    required String title,
    required String body,
  });
}
