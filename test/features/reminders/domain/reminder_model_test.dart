import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/reminders/data/models/reminder_model.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';

Map<String, dynamic> _map({
  Object? id = '1',
  String type = 'appointment',
  String? dueAt = '2026-08-22T15:00:00.000',
}) => {
  'id': id,
  'title': 'Dentist',
  'body': 'Checkup',
  'type': type,
  'due_at': dueAt,
  'repeat_rule': 'never',
  'status': 'pending',
  'created_by': 'mom',
  'created_at': '2026-08-01',
};

void main() {
  group('ReminderType.fromString', () {
    test('parses every known value', () {
      for (final type in ReminderType.values) {
        expect(ReminderType.fromString(type.value), type);
      }
    });

    test('returns null for unknown and null input', () {
      expect(ReminderType.fromString('nope'), isNull);
      expect(ReminderType.fromString(null), isNull);
    });
  });

  group('ReminderModel.fromMap', () {
    test('formats ISO due date to display format', () {
      final model = ReminderModel.fromMap(_map());
      expect(model.title, 'Dentist');
      expect(model.type, ReminderType.appointment);
      expect(model.dueDate, '22/08/2026 15:00');
    });

    test('keeps already-formatted display dates untouched', () {
      final model = ReminderModel.fromMap(_map(dueAt: '22/08/2026 15:00'));
      expect(model.dueDate, '22/08/2026 15:00');
    });

    test('maps null due date to empty string', () {
      final model = ReminderModel.fromMap(_map(dueAt: null));
      expect(model.dueDate, '');
    });

    test('coerces int ids to string', () {
      final model = ReminderModel.fromMap(_map(id: 42));
      expect(model.id, '42');
    });

    test('throws FormatException on unknown type', () {
      expect(
        () => ReminderModel.fromMap(_map(type: 'nope')),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ReminderModel payloads', () {
    test('toCreate includes family id and null due_at when empty', () {
      const model = ReminderModel(
        title: 'T',
        body: 'B',
        id: '',
        type: ReminderType.chores,
        dueDate: '',
        repeatRule: 'never',
        status: 'pending',
        createdBy: 'u1',
        createdAt: '2026-08-01',
      );
      final payload = model.toCreate('fam-1');
      expect(payload['family_id'], 'fam-1');
      expect(payload['due_at'], isNull);
      expect(payload['type'], 'chores');
    });

    test('toUpdate omits server-managed fields', () {
      const model = ReminderModel(
        title: 'T',
        body: 'B',
        id: '1',
        type: ReminderType.birthday,
        dueDate: '22/08/2026 15:00',
        repeatRule: 'yearly',
        status: 'pending',
        createdBy: 'u1',
        createdAt: '2026-08-01',
      );
      final payload = model.toUpdate();
      expect(payload['title'], 'T');
      expect(payload.keys, isNot(contains('family_id')));
      expect(payload.keys, isNot(contains('status')));
    });
  });
}
