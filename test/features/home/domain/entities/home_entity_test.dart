import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/home/domain/entities/home_entity.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';

ReminderEntity reminder(String id) => ReminderEntity(
  title: 'T $id',
  body: '',
  id: id,
  type: ReminderType.custom,
  dueDate: '',
  repeatRule: 'never',
  status: 'pending',
  createdBy: 'u1',
  createdAt: '',
);

void main() {
  group('HomeEntity.copyWith', () {
    test('overrides only the given fields', () {
      final original = HomeEntity(
        peopleInCircle: [PersonEntity(id: 'u1', name: 'Ana')],
        hasReminders: true,
        familyName: 'Fam',
        myRole: 'admin',
        activeMembers: 1,
        reminders: [reminder('1')],
      );

      final updated = original.copyWith(familyName: 'New', activeMembers: 2);

      expect(updated.familyName, 'New');
      expect(updated.activeMembers, 2);
      expect(updated.hasReminders, isTrue);
      expect(updated.myRole, 'admin');
      expect(updated.peopleInCircle, hasLength(1));
      expect(updated.reminders, hasLength(1));
    });

    test('keeps every field when called empty', () {
      final original = HomeEntity(peopleInCircle: []);

      final copy = original.copyWith();

      expect(copy.peopleInCircle, isEmpty);
      expect(copy.hasReminders, isFalse);
      expect(copy.familyName, '');
      expect(copy.myRole, '');
      expect(copy.activeMembers, 0);
      expect(copy.reminders, isEmpty);
    });
  });

  group('HomeEntity equality', () {
    test('equal entities compare equal with matching hash codes', () {
      final first = HomeEntity(
        peopleInCircle: [PersonEntity(id: 'u1')],
        familyName: 'Fam',
        reminders: [reminder('1')],
      );
      final second = HomeEntity(
        peopleInCircle: [PersonEntity(id: 'u1')],
        familyName: 'Fam',
        reminders: [reminder('1')],
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('identical instance is equal to itself', () {
      final entity = HomeEntity(peopleInCircle: []);

      expect(entity == entity, isTrue);
    });

    test('differs when any field differs', () {
      final base = HomeEntity(peopleInCircle: []);

      final Object other = 'not-an-entity';
      expect(base == other, isFalse);
      expect(base, isNot(base.copyWith(hasReminders: true)));
      expect(base, isNot(base.copyWith(familyName: 'Fam')));
      expect(base, isNot(base.copyWith(myRole: 'admin')));
      expect(base, isNot(base.copyWith(activeMembers: 1)));
      expect(
        base,
        isNot(base.copyWith(peopleInCircle: [PersonEntity(id: 'u1')])),
      );
      expect(base, isNot(base.copyWith(reminders: [reminder('1')])));
    });
  });
}
