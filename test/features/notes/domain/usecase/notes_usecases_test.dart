import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/notes/data/models/note_model.dart';
import 'package:house_mira/features/notes/domain/entities/note_entity.dart';
import 'package:house_mira/features/notes/domain/repository/notes_repository.dart';
import 'package:house_mira/features/notes/domain/usecase/create_note_usecase.dart';
import 'package:house_mira/features/notes/domain/usecase/delete_note_usecase.dart';
import 'package:house_mira/features/notes/domain/usecase/get_notes_usecase.dart';
import 'package:house_mira/features/notes/domain/usecase/update_note_usecase.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotes extends Mock implements NotesRepository {}

class _MockPeople extends Mock implements PeopleRepository {}

NoteModel model() {
  final now = DateTime.utc(2026);
  return NoteModel(
    id: 'n1',
    familyId: 'f1',
    createdBy: 'u1',
    title: 'T',
    content: 'C',
    color: 'blue',
    createdAt: now,
    updatedAt: now,
  );
}

NoteEntity entity({String id = '1', String createdBy = 'u1'}) {
  final now = DateTime.utc(2026);
  return NoteEntity(
    id: id,
    familyId: 'f1',
    createdBy: createdBy,
    title: 'T $id',
    content: 'C',
    color: 'yellow',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late _MockNotes notes;
  late _MockPeople people;

  setUpAll(() {
    registerFallbackValue(model());
  });

  setUp(() {
    notes = _MockNotes();
    people = _MockPeople();
  });

  group('GetNotesUsecase', () {
    test('returns notes with creator display names resolved', () async {
      when(() => notes.getNotes('f1')).thenAnswer(
        (_) async => Right<Failure, List<NoteEntity>>([
          entity(),
          entity(id: '2', createdBy: 'unknown'),
        ]),
      );
      when(
        () => people.getProfilesWithRoleForFamily('f1'),
      ).thenAnswer((_) async => [const PersonEntity(id: 'u1', name: 'Mom')]);

      final result = await GetNotesUsecase(
        repository: notes,
        peopleRepository: people,
      )('f1');

      final list = result.getRight().toNullable()!;
      expect(list, hasLength(2));
      expect(list.first.createdBy, 'Mom');
      // Unknown creators keep their raw id instead of a fallback name.
      expect(list.last.createdBy, 'unknown');
    });

    test('keeps notes whose creator id is missing', () async {
      when(() => notes.getNotes('f1')).thenAnswer(
        (_) async => Right<Failure, List<NoteEntity>>([entity()]),
      );
      when(
        () => people.getProfilesWithRoleForFamily('f1'),
      ).thenAnswer((_) async => [const PersonEntity(name: 'Nameless')]);

      final result = await GetNotesUsecase(
        repository: notes,
        peopleRepository: people,
      )('f1');

      // A profile without an id never matches: the raw id is preserved.
      expect(result.getRight().toNullable()!.single.createdBy, 'u1');
    });

    test('propagates Left failures', () async {
      when(() => notes.getNotes('f1')).thenAnswer(
        (_) async => Left(Failure(message: 'boom')),
      );

      final result = await GetNotesUsecase(
        repository: notes,
        peopleRepository: people,
      )('f1');

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable()?.message, 'boom');
    });
  });

  group('CreateNoteUsecase', () {
    test('delegates creation and returns the new id', () async {
      when(() => notes.createNote(any(), 'f1')).thenAnswer(
        (_) async => const Right('new-id'),
      );

      final result = await CreateNoteUsecase(repository: notes)(
        model(),
        'f1',
      );

      expect(result.getRight().toNullable(), 'new-id');
    });

    test('propagates Left failures', () async {
      when(() => notes.createNote(any(), 'f1')).thenAnswer(
        (_) async => Left(Failure(message: 'boom')),
      );

      final result = await CreateNoteUsecase(repository: notes)(
        model(),
        'f1',
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('UpdateNoteUsecase', () {
    test('delegates the update', () async {
      when(
        () => notes.updateNote(any()),
      ).thenAnswer((_) async => const Right(true));

      final result = await UpdateNoteUsecase(repository: notes)(model());

      expect(result.getRight().toNullable(), isTrue);
    });

    test('propagates Left failures', () async {
      when(() => notes.updateNote(any())).thenAnswer(
        (_) async => Left(Failure(message: 'boom')),
      );

      final result = await UpdateNoteUsecase(repository: notes)(model());

      expect(result.isLeft(), isTrue);
    });
  });

  group('DeleteNoteUsecase', () {
    test('delegates the delete', () async {
      when(
        () => notes.deleteNote('n1'),
      ).thenAnswer((_) async => const Right(true));

      final result = await DeleteNoteUsecase(repository: notes)('n1');

      expect(result.getRight().toNullable(), isTrue);
    });

    test('propagates Left failures', () async {
      when(() => notes.deleteNote('n1')).thenAnswer(
        (_) async => Left(Failure(message: 'boom')),
      );

      final result = await DeleteNoteUsecase(repository: notes)('n1');

      expect(result.isLeft(), isTrue);
    });
  });
}
