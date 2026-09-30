import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/notes/domain/entities/note_color.dart';
import 'package:house_mira/features/notes/domain/entities/note_entity.dart';

Map<String, dynamic> row({
  String id = '11111111-1111-1111-1111-111111111111',
  String familyId = '22222222-2222-2222-2222-222222222222',
  String createdBy = '33333333-3333-3333-3333-333333333333',
  Object? title = 'Title',
  Object? content = 'Content',
  String? color = 'yellow',
  String createdAt = '2026-09-30T10:00:00.000Z',
  String updatedAt = '2026-09-30T10:00:00.000Z',
}) {
  return {
    'id': id,
    'family_id': familyId,
    'created_by': createdBy,
    'title': title,
    'content': content,
    'color': color,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

void main() {
  group('NoteEntity.from', () {
    test('parses a valid row', () {
      final note = NoteEntity.from(row());
      expect(note, isNotNull);
      expect(note!.title, 'Title');
      expect(note.color, 'yellow');
    });

    test('returns null for non-map input', () {
      expect(NoteEntity.from('nope'), isNull);
      expect(NoteEntity.from(null), isNull);
      expect(NoteEntity.from(<String>[]), isNull);
    });

    test('returns null per missing/empty id field', () {
      final missing = row()..remove('id');
      expect(NoteEntity.from(missing), isNull);
      expect(NoteEntity.from(row(id: '')), isNull);
    });

    test('returns null per missing family/creator id', () {
      final noFamily = row()..remove('family_id');
      expect(NoteEntity.from(noFamily), isNull);
      expect(NoteEntity.from(row(familyId: '')), isNull);
      final noCreator = row()..remove('created_by');
      expect(NoteEntity.from(noCreator), isNull);
      expect(NoteEntity.from(row(createdBy: '')), isNull);
    });

    test('returns null for non-string title/content', () {
      expect(NoteEntity.from(row(title: 42)), isNull);
      expect(NoteEntity.from(row(content: 42)), isNull);
    });

    test('returns null for empty-after-trim title/content', () {
      expect(NoteEntity.from(row(title: '   ')), isNull);
      expect(NoteEntity.from(row(content: '  \n ')), isNull);
    });

    test('returns null for over-limit title/content', () {
      expect(NoteEntity.from(row(title: 'a' * 101)), isNull);
      expect(NoteEntity.from(row(content: 'b' * 301)), isNull);
      expect(NoteEntity.from(row(title: 'a' * 100)), isNotNull);
      expect(NoteEntity.from(row(content: 'b' * 300)), isNotNull);
    });

    test('returns null for non-allowlisted color', () {
      expect(NoteEntity.from(row(color: 'red')), isNull);
      expect(NoteEntity.from(row(color: 'YELLOW')), isNull);
      expect(NoteEntity.from(row(color: null)), isNull);
      for (final c in noteColorAllowlist) {
        expect(NoteEntity.from(row(color: c)), isNotNull);
      }
    });

    test('returns null for bad timestamps (no fallback)', () {
      expect(NoteEntity.from(row(createdAt: 'not-a-date')), isNull);
      expect(NoteEntity.from(row(updatedAt: '')), isNull);
    });
  });

  group('NoteEntity value semantics', () {
    test('copyWith replaces selected fields', () {
      final note = NoteEntity.from(row())!;
      final updated = note.copyWith(title: 'New', color: 'pink');
      expect(updated.title, 'New');
      expect(updated.color, 'pink');
      expect(updated.id, note.id);
    });

    test('== and hashCode', () {
      final a = NoteEntity.from(row())!;
      final b = NoteEntity.from(row())!;
      final c = b.copyWith(title: 'Other');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals('string')));
    });

    test('const constructor', () {
      final now = DateTime.utc(2026);
      final note = NoteEntity(
        id: 'i',
        familyId: 'f',
        createdBy: 'u',
        title: 't',
        content: 'c',
        color: 'blue',
        createdAt: now,
        updatedAt: now,
      );
      expect(note, isA<NoteEntity>());
    });
  });
}
