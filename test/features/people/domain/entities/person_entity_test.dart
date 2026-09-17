import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';

void main() {
  group('PersonEntity.from', () {
    test('parses a valid profile map', () {
      final person = PersonEntity.from({
        'id': 'u1',
        'full_name': 'Ana',
        'email': 'ana@example.com',
        'phone': '123',
        'role': 'admin',
      });

      expect(person, isNotNull);
      expect(person!.id, 'u1');
      expect(person.name, 'Ana');
      expect(person.email, 'ana@example.com');
      expect(person.phone, '123');
      expect(person.role, 'admin');
    });

    test('returns null for non-map payloads instead of guessing', () {
      expect(PersonEntity.from(null), isNull);
      expect(PersonEntity.from('nope'), isNull);
      expect(PersonEntity.from([1, 2]), isNull);
    });

    test('tolerates missing keys as null fields', () {
      final person = PersonEntity.from(<String, dynamic>{});

      expect(person, isNotNull);
      expect(person!.id, isNull);
      expect(person.name, isNull);
    });
  });

  group('PersonEntity.copyWith', () {
    test('overrides only the given fields', () {
      const original = PersonEntity(
        id: 'u1',
        name: 'Ana',
        email: 'ana@example.com',
        phone: '123',
        role: 'member',
      );

      final updated = original.copyWith(name: 'Ana B', role: 'admin');

      expect(updated.id, 'u1');
      expect(updated.name, 'Ana B');
      expect(updated.email, 'ana@example.com');
      expect(updated.phone, '123');
      expect(updated.role, 'admin');
    });

    test('keeps every field when called empty', () {
      const original = PersonEntity(id: 'u1', name: 'Ana');

      final copy = original.copyWith();

      expect(copy.id, 'u1');
      expect(copy.name, 'Ana');
      expect(copy.email, isNull);
      expect(copy.phone, isNull);
      expect(copy.role, isNull);
    });
  });
}
