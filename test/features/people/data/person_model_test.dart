import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/people/data/models/person_model.dart';

void main() {
  group('PersonModel.fromMap', () {
    test('parses string ids', () {
      final model = PersonModel.fromMap(const {
        'id': 'u1',
        'name': 'Ana',
        'email': 'a@b.c',
        'phone': '123',
      });
      expect(model.id, 'u1');
      expect(model.name, 'Ana');
    });

    test('coerces int ids to string', () {
      final model = PersonModel.fromMap(const {
        'id': 7,
        'name': 'Ana',
        'email': 'a@b.c',
        'phone': '123',
      });
      expect(model.id, '7');
    });

    test('round-trips through toMap/fromJson', () {
      const model = PersonModel(
        id: 'u1',
        name: 'Ana',
        email: 'a@b.c',
        phone: '123',
      );
      final restored = PersonModel.fromJson(model.toJson());
      expect(restored.id, 'u1');
      expect(restored.email, 'a@b.c');
    });
  });
}
