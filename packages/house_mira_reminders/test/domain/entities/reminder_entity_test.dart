import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira_reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira_reminders/domain/entities/reminder_type.dart';

// Fresh (deliberately non-const) instances so `identical` never
// short-circuits `==` and the full `&&` chain is covered.
ReminderEntity base() => ReminderEntity(
  title: 'Title',
  body: 'Body',
  id: '1',
  type: ReminderType.appointment,
  dueDate: '15/09/2026 09:30',
  repeatRule: 'never',
  status: 'pending',
  createdBy: 'u1',
  createdAt: '2026-09-01',
);

void main() {
  group('ReminderEntity.copyWith', () {
    test('overrides only the given fields', () {
      final updated = base().copyWith(
        title: 'New',
        type: ReminderType.chores,
        status: 'done',
      );

      expect(updated.title, 'New');
      expect(updated.type, ReminderType.chores);
      expect(updated.status, 'done');
      expect(updated.body, 'Body');
      expect(updated.id, '1');
      expect(updated.dueDate, '15/09/2026 09:30');
      expect(updated.repeatRule, 'never');
      expect(updated.createdBy, 'u1');
      expect(updated.createdAt, '2026-09-01');
    });

    test('keeps every field when called empty', () {
      final copy = base().copyWith();

      expect(copy.title, 'Title');
      expect(copy.body, 'Body');
      expect(copy.id, '1');
      expect(copy.type, ReminderType.appointment);
      expect(copy.dueDate, '15/09/2026 09:30');
      expect(copy.repeatRule, 'never');
      expect(copy.status, 'pending');
      expect(copy.createdBy, 'u1');
      expect(copy.createdAt, '2026-09-01');
    });
  });

  group('ReminderEntity equality', () {
    test('identical instances are equal', () {
      final original = base();

      expect(original == original, isTrue);
      expect(original.hashCode, original.copyWith().hashCode);
    });

    test('equal field values compare equal', () {
      expect(base(), base());
      expect(base().hashCode, base().hashCode);
    });

    test('differing fields and types compare unequal', () {
      expect(base() == base().copyWith(createdAt: '2026-09-02'), isFalse);
      expect(base() == Object(), isFalse);
    });
  });
}
