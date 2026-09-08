import 'package:intl/intl.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';

/// Shared parsing for reminder due dates.
///
/// Stored values can be:
/// - '' (no date, persisted as null in Supabase)
/// - 'dd/MM/yyyy HH:mm' (display format from [ReminderModel])
/// - 'dd/MM/yyyy' (legacy / date-only)
/// - ISO-8601 (directly from create flow before formatting)
class ReminderDateUtils {
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final RegExp _timePattern = RegExp(
    r'(\d{1,2}:\d{2}(?:\s*(?:AM|PM|am|pm))?)',
  );

  static DateTime? parseDueDate(String rawDueDate) {
    final value = rawDueDate.trim();
    if (value.isEmpty) return null;

    final dateTime = _dateTimeFormat.tryParse(value);
    if (dateTime != null) return dateTime;

    final date = _dateFormat.tryParse(value);
    if (date != null) return date;

    return DateTime.tryParse(value);
  }

  static bool hasDueDate(String rawDueDate) => parseDueDate(rawDueDate) != null;

  static String dateKey(DateTime date) => _dateFormat.format(date);

  static String? extractTimeLabel(String rawDueDate) {
    if (rawDueDate.trim().isEmpty) return null;
    final match = _timePattern.firstMatch(rawDueDate);
    final value = match?.group(0)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Normalizes repeat rules: missing/legacy values mean "never".
  static String normalizeRepeatRule(String rawRepeatRule) {
    final rule = rawRepeatRule.trim().toLowerCase();
    if (rule.isEmpty ||
        rule == 'none' ||
        rule == 'no_repeat' ||
        rule == 'no-repeat' ||
        rule == 'does_not_repeat') {
      return 'never';
    }
    return rule;
  }

  static DateTime _dayOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Whether [reminder] occurs on [date], comparing calendar days only
  /// (time-of-day is ignored so a 14:00 reminder still matches its day).
  static bool occursOnDate(ReminderEntity reminder, DateTime date) {
    final dueDate = parseDueDate(reminder.dueDate);
    if (dueDate == null) return false;

    final day = _dayOnly(date);
    final dueDay = _dayOnly(dueDate);
    if (day.isBefore(dueDay)) return false;

    switch (normalizeRepeatRule(reminder.repeatRule)) {
      case 'never':
        return day == dueDay;
      case 'daily':
        return true;
      case 'weekly':
        return day.weekday == dueDay.weekday;
      case 'monthly':
        return day.day == dueDay.day;
      default:
        return false;
    }
  }
}
