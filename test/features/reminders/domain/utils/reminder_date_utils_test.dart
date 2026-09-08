import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/utils/reminder_date_utils.dart';

ReminderEntity makeReminder({
  required String dueDate,
  String repeatRule = 'never',
}) => ReminderEntity(
  title: 'Test',
  body: '',
  id: '1',
  type: ReminderType.appointment,
  dueDate: dueDate,
  repeatRule: repeatRule,
  status: 'pending',
  createdBy: '',
  createdAt: '',
);

void main() {
  group('ReminderDateUtils.parseDueDate', () {
    test('returns null for empty string (dateless reminder)', () {
      expect(ReminderDateUtils.parseDueDate(''), isNull);
      expect(ReminderDateUtils.parseDueDate('   '), isNull);
    });

    test('parses display format dd/MM/yyyy HH:mm', () {
      final date = ReminderDateUtils.parseDueDate('15/09/2026 09:30');
      expect(date, isNotNull);
      expect(date!.year, 2026);
      expect(date.month, 9);
      expect(date.day, 15);
      expect(date.hour, 9);
      expect(date.minute, 30);
    });

    test('parses date-only format dd/MM/yyyy', () {
      final date = ReminderDateUtils.parseDueDate('15/09/2026');
      expect(date, isNotNull);
      expect(date!.day, 15);
    });

    test('parses ISO-8601', () {
      final date = ReminderDateUtils.parseDueDate('2026-09-15T09:30:00.000');
      expect(date, isNotNull);
      expect(date!.year, 2026);
    });

    test('returns null for invalid strings instead of fallback', () {
      expect(ReminderDateUtils.parseDueDate('not-a-date'), isNull);
    });
  });

  group('ReminderDateUtils.extractTimeLabel', () {
    test('returns null for dateless', () {
      expect(ReminderDateUtils.extractTimeLabel(''), isNull);
    });

    test('extracts HH:mm from display format', () {
      expect(ReminderDateUtils.extractTimeLabel('15/09/2026 09:30'), '09:30');
    });
  });

  group('ReminderDateUtils.occursOnDate', () {
    String fmt(DateTime d) {
      final day = d.day.toString().padLeft(2, '0');
      final month = d.month.toString().padLeft(2, '0');
      return '$day/$month/${d.year}';
    }

    test('matches its own day even when due time is later that day', () {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      // Midnight calendar cell vs 14:00 reminder must still match.
      final reminder = makeReminder(dueDate: '${fmt(tomorrow)} 14:00');
      final cell = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      expect(ReminderDateUtils.occursOnDate(reminder, cell), isTrue);
    });

    test('never matches date-only due date, not adjacent days', () {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final reminder = makeReminder(dueDate: fmt(tomorrow));
      final cell = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      expect(ReminderDateUtils.occursOnDate(reminder, cell), isTrue);
      expect(
        ReminderDateUtils.occursOnDate(
          reminder,
          cell.subtract(const Duration(days: 1)),
        ),
        isFalse,
      );
      expect(
        ReminderDateUtils.occursOnDate(
          reminder,
          cell.add(const Duration(days: 1)),
        ),
        isFalse,
      );
    });

    test('empty or none repeat rule is treated as never', () {
      final now = DateTime.now();
      final cell = DateTime(now.year, now.month, now.day);
      for (final rule in ['', '  ', 'none', 'None']) {
        final reminder = makeReminder(dueDate: fmt(now), repeatRule: rule);
        expect(
          ReminderDateUtils.occursOnDate(reminder, cell),
          isTrue,
          reason: 'rule "$rule" should behave as never',
        );
      }
    });

    test('returns false for dateless reminders', () {
      final now = DateTime.now();
      final reminder = makeReminder(dueDate: '');
      expect(
        ReminderDateUtils.occursOnDate(
          reminder,
          DateTime(now.year, now.month, now.day),
        ),
        isFalse,
      );
    });

    test('daily occurs on due day and after, not before', () {
      final now = DateTime.now();
      final reminder = makeReminder(
        dueDate: '${fmt(now)} 09:00',
        repeatRule: 'daily',
      );
      final today = DateTime(now.year, now.month, now.day);
      expect(ReminderDateUtils.occursOnDate(reminder, today), isTrue);
      expect(
        ReminderDateUtils.occursOnDate(
          reminder,
          today.add(const Duration(days: 5)),
        ),
        isTrue,
      );
      expect(
        ReminderDateUtils.occursOnDate(
          reminder,
          today.subtract(const Duration(days: 1)),
        ),
        isFalse,
      );
    });

    test('weekly occurs on same weekday on/after due day', () {
      final now = DateTime.now();
      final reminder = makeReminder(dueDate: fmt(now), repeatRule: 'weekly');
      final today = DateTime(now.year, now.month, now.day);
      expect(ReminderDateUtils.occursOnDate(reminder, today), isTrue);
      expect(
        ReminderDateUtils.occursOnDate(
          reminder,
          today.add(const Duration(days: 7)),
        ),
        isTrue,
      );
      expect(
        ReminderDateUtils.occursOnDate(
          reminder,
          today.add(const Duration(days: 1)),
        ),
        isFalse,
      );
    });

    test('monthly occurs on same day-of-month on/after due day', () {
      final now = DateTime.now();
      // Day 15 exists in every month, avoiding overflow flakiness.
      final due = DateTime(now.year, now.month, 15);
      final reminder = makeReminder(dueDate: fmt(due), repeatRule: 'monthly');
      expect(ReminderDateUtils.occursOnDate(reminder, due), isTrue);
      expect(
        ReminderDateUtils.occursOnDate(
          reminder,
          DateTime(due.year, due.month + 1, 15),
        ),
        isTrue,
      );
      expect(
        ReminderDateUtils.occursOnDate(
          reminder,
          DateTime(due.year, due.month, 16),
        ),
        isFalse,
      );
    });

    test('unknown repeat rule never occurs', () {
      final now = DateTime.now();
      final reminder = makeReminder(dueDate: fmt(now), repeatRule: 'yearly');
      expect(
        ReminderDateUtils.occursOnDate(
          reminder,
          DateTime(now.year, now.month, now.day),
        ),
        isFalse,
      );
    });
  });
}
