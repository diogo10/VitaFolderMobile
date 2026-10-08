import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/core/subscriptions/subscription_service.dart';
import 'package:house_mira/features/notes/application/is_at_note_limit_usecase.dart';
import 'package:house_mira/features/notes/domain/entities/note_entity.dart';
import 'package:house_mira/features/notes/domain/repository/notes_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockSubscriptions extends Mock implements SubscriptionService {}

class _MockNotes extends Mock implements NotesRepository {}

NoteEntity row(String id) {
  final now = DateTime.utc(2026);
  return NoteEntity(
    id: id,
    familyId: 'f1',
    createdBy: 'u1',
    title: 'T $id',
    content: 'C',
    color: 'yellow',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late _MockSubscriptions subscriptions;
  late _MockNotes notes;

  setUp(() {
    subscriptions = _MockSubscriptions();
    notes = _MockNotes();
    when(() => subscriptions.isPro()).thenAnswer((_) async => false);
  });

  IsAtNoteLimitUsecase build() => IsAtNoteLimitUsecase(
    subscriptionService: subscriptions,
    notesRepository: notes,
  );

  test('paid users never hit the cap (no count lookup)', () async {
    when(() => subscriptions.isPro()).thenAnswer((_) async => true);
    expect(await build()(familyId: 'f1'), isFalse);
    verifyNever(() => notes.getNotes(any()));
  });

  test('null familyId fails open', () async {
    expect(await build()(familyId: null), isFalse);
    verifyNever(() => notes.getNotes(any()));
  });

  test('true at cap, false below cap', () async {
    when(() => notes.getNotes('f1')).thenAnswer(
      (_) async => Right<Failure, List<NoteEntity>>(
        List.generate(3, (i) => row('n$i')),
      ),
    );
    expect(await build()(familyId: 'f1'), isTrue);

    when(() => notes.getNotes('f1')).thenAnswer(
      (_) async => Right<Failure, List<NoteEntity>>(
        List.generate(2, (i) => row('n$i')),
      ),
    );
    expect(await build()(familyId: 'f1'), isFalse);
  });

  test('count lookup failure fails open', () async {
    when(() => notes.getNotes('f1')).thenAnswer(
      (_) async => Left(Failure(message: 'boom')),
    );
    expect(await build()(familyId: 'f1'), isFalse);
  });

  test('billing lookup throw fails open', () async {
    when(() => subscriptions.isPro()).thenThrow(Exception('billing down'));
    expect(await build()(familyId: 'f1'), isFalse);
  });

  test('count lookup throw fails open', () async {
    when(() => notes.getNotes('f1')).thenThrow(Exception('db down'));
    expect(await build()(familyId: 'f1'), isFalse);
  });
}
