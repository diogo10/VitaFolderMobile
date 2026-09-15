import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_lead_time.dart';

void main() {
  group('ReminderLeadTime', () {
    test('maps each option to minutes', () {
      expect(ReminderLeadTime.atTime.minutes, 0);
      expect(ReminderLeadTime.fifteenMinutes.minutes, 15);
      expect(ReminderLeadTime.oneHour.minutes, 60);
      expect(ReminderLeadTime.oneDay.minutes, 24 * 60);
    });

    test('defaults to fifteen minutes', () {
      expect(ReminderLeadTime.defaultLeadTime, ReminderLeadTime.fifteenMinutes);
    });

    test('parses stored minutes', () {
      expect(ReminderLeadTime.fromMinutes(0), ReminderLeadTime.atTime);
      expect(ReminderLeadTime.fromMinutes(15), ReminderLeadTime.fifteenMinutes);
      expect(ReminderLeadTime.fromMinutes(60), ReminderLeadTime.oneHour);
      expect(ReminderLeadTime.fromMinutes(1440), ReminderLeadTime.oneDay);
    });

    test('returns null for unknown or missing minutes', () {
      expect(ReminderLeadTime.fromMinutes(42), isNull);
      expect(ReminderLeadTime.fromMinutes(null), isNull);
    });
  });
}
