/// Lead time options for per-device reminder notifications.
///
/// Stored as minutes so it can be persisted without depending on enum order.
enum ReminderLeadTime {
  atTime(0),
  fifteenMinutes(15),
  oneHour(60),
  oneDay(24 * 60);

  const ReminderLeadTime(this.minutes);

  final int minutes;

  /// Preselected option when the user enables notifications.
  static const ReminderLeadTime defaultLeadTime = fifteenMinutes;

  /// Returns `null` when [minutes] does not match any option instead of
  /// silently falling back, so callers decide explicitly.
  static ReminderLeadTime? fromMinutes(int? minutes) {
    if (minutes == null) return null;
    for (final leadTime in ReminderLeadTime.values) {
      if (leadTime.minutes == minutes) return leadTime;
    }
    return null;
  }
}
