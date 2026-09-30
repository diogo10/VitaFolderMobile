import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/notes/data/models/note_model.dart';
import 'package:house_mira/features/notes/domain/entities/note_entity.dart';

void main() {
  Map<String, dynamic> validRow() => {
    'id': 'n1',
    'family_id': 'f1',
    'created_by': 'u1',
    'title': 'Title',
    'content': 'Content',
    'color': 'green',
    'created_at': '2026-09-30T10:00:00.000Z',
    'updated_at': '2026-09-30T11:00:00.000Z',
  };

  group('NoteModel', () {
    test('fromMap parses a valid row', () {
      final model = NoteModel.fromMap(validRow());
      expect(model, isA<NoteEntity>());
      expect(model.color, 'green');
    });

    test('fromMap throws FormatException on invalid rows', () {
      expect(
        () => NoteModel.fromMap({...validRow(), 'color': 'red'}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => NoteModel.fromMap({...validRow(), 'title': '   '}),
        throwsA(isA<FormatException>()),
      );
    });

    test('toCreate sends only name fields + family scope', () {
      final model = NoteModel.fromMap(validRow());
      final payload = model.toCreate('f1');
      expect(payload, {
        'title': 'Title',
        'content': 'Content',
        'color': 'green',
        'family_id': 'f1',
      });
    });

    test('toUpdate sends title/content/color only', () {
      final model = NoteModel.fromMap(validRow());
      expect(model.toUpdate(), {
        'title': 'Title',
        'content': 'Content',
        'color': 'green',
      });
    });
  });
}
