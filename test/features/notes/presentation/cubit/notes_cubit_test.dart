import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/core/subscriptions/subscription_service.dart';
import 'package:house_mira/features/notes/application/is_at_note_limit_usecase.dart';
import 'package:house_mira/features/notes/data/models/note_model.dart';
import 'package:house_mira/features/notes/domain/entities/note_entity.dart';
import 'package:house_mira/features/notes/domain/repository/notes_repository.dart';
import 'package:house_mira/features/notes/domain/usecase/create_note_usecase.dart';
import 'package:house_mira/features/notes/domain/usecase/delete_note_usecase.dart';
import 'package:house_mira/features/notes/domain/usecase/get_notes_usecase.dart';
import 'package:house_mira/features/notes/domain/usecase/update_note_usecase.dart';
import 'package:house_mira/features/notes/presentation/cubit/notes_cubit.dart';
import 'package:house_mira/features/notes/presentation/cubit/notes_state.dart';
import 'package:house_mira/features/people/domain/entities/family_entity.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotes extends Mock implements NotesRepository {}

class _MockPeople extends Mock implements PeopleRepository {}

class _MockAuth extends Mock implements AuthService {}

class _MockSubscriptions extends Mock implements SubscriptionService {}

NoteEntity note({String id = 'n1'}) {
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
  late _MockNotes notes;
  late _MockPeople people;
  late _MockAuth auth;
  late _MockSubscriptions subscriptions;

  setUpAll(() {
    registerFallbackValue(note());
    final now = DateTime.utc(2026);
    registerFallbackValue(
      NoteModel(
        id: 'fb',
        familyId: 'f1',
        createdBy: 'u1',
        title: 'fb',
        content: 'fb',
        color: 'yellow',
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  setUp(() {
    notes = _MockNotes();
    people = _MockPeople();
    auth = _MockAuth();
    subscriptions = _MockSubscriptions();
    // Paid by default so existing tests exercise the uncapped path;
    // limit tests override with `isPro(userId:) == false`.
    when(
      () => subscriptions.isPro(userId: any(named: 'userId')),
    ).thenAnswer((_) async => true);
    when(() => people.getMyFamily()).thenAnswer(
      (_) async => Right<Exception, FamilyEntity>(
        FamilyEntity(name: 'Smith Family', inviteCode: 'ABC'),
      ),
    );
    when(
      () => people.getProfilesWithRoleForFamily(any()),
    ).thenAnswer((_) async => const <PersonEntity>[]);
  });

  NotesCubit buildCubit() => NotesCubit(
    getNotesUsecase: GetNotesUsecase(
      repository: notes,
      peopleRepository: people,
    ),
    createNoteUsecase: CreateNoteUsecase(repository: notes),
    updateNoteUsecase: UpdateNoteUsecase(repository: notes),
    deleteNoteUsecase: DeleteNoteUsecase(repository: notes),
    peopleRepository: people,
    authService: auth,
    isAtNoteLimitUsecase: IsAtNoteLimitUsecase(
      subscriptionService: subscriptions,
      notesRepository: notes,
    ),
  );

  void stubFamily({String userId = 'u1', String familyId = 'f1'}) {
    when(() => auth.currentUserId).thenReturn(userId);
    when(
      () => people.getFamilyIdsForUser(userId),
    ).thenAnswer((_) async => [familyId]);
  }

  group('NotesCubit.loadNotes', () {
    blocTest<NotesCubit, NotesState>(
      'empty → NotesLoaded([])',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => notes.getNotes('f1'),
        ).thenAnswer((_) async => const Right<Failure, List<NoteEntity>>([]));
      },
      act: (cubit) => cubit.loadNotes(),
      expect: () => [isA<NotesLoading>(), isA<NotesLoaded>()],
      verify: (cubit) {
        expect((cubit.state as NotesLoaded).notes, isEmpty);
      },
    );

    blocTest<NotesCubit, NotesState>(
      'populated list and family name',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(() => notes.getNotes('f1')).thenAnswer(
          (_) async =>
              Right<Failure, List<NoteEntity>>([note(), note(id: 'n2')]),
        );
      },
      act: (cubit) => cubit.loadNotes(),
      expect: () => [isA<NotesLoading>(), isA<NotesLoaded>()],
      verify: (cubit) {
        expect((cubit.state as NotesLoaded).notes, hasLength(2));
        expect(cubit.familyName, 'Smith Family');
      },
    );

    blocTest<NotesCubit, NotesState>(
      'unauthenticated when no currentUserId',
      build: buildCubit,
      setUp: () {
        when(() => auth.currentUserId).thenReturn(null);
      },
      act: (cubit) => cubit.loadNotes(),
      expect: () => [isA<NotesLoading>(), isA<NotesUnauthenticated>()],
    );

    blocTest<NotesCubit, NotesState>(
      'failure maps to NotesFailure',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => notes.getNotes('f1'),
        ).thenAnswer((_) async => Left(Failure(message: 'offline')));
      },
      act: (cubit) => cubit.loadNotes(),
      expect: () => [isA<NotesLoading>(), isA<NotesFailure>()],
    );

    blocTest<NotesCubit, NotesState>(
      'explicit familyId skips resolution',
      build: buildCubit,
      setUp: () {
        when(() => auth.currentUserId).thenReturn('u1');
        when(
          () => notes.getNotes('other'),
        ).thenAnswer((_) async => const Right<Failure, List<NoteEntity>>([]));
      },
      act: (cubit) => cubit.loadNotes(familyId: 'other'),
      expect: () => [isA<NotesLoading>(), isA<NotesLoaded>()],
      verify: (_) {
        verifyNever(() => people.getFamilyIdsForUser(any()));
      },
    );

    blocTest<NotesCubit, NotesState>(
      'no family → NotesLoaded([])',
      build: buildCubit,
      setUp: () {
        when(() => auth.currentUserId).thenReturn('u1');
        when(
          () => people.getFamilyIdsForUser('u1'),
        ).thenAnswer((_) async => <String>[]);
      },
      act: (cubit) => cubit.loadNotes(),
      expect: () => [isA<NotesLoading>(), isA<NotesLoaded>()],
    );

    blocTest<NotesCubit, NotesState>(
      'resolves family scope fresh on every load (no stale cache)',
      build: buildCubit,
      setUp: () {
        when(() => auth.currentUserId).thenReturn('u1');
        var calls = 0;
        when(() => people.getFamilyIdsForUser('u1')).thenAnswer((_) async {
          calls++;
          if (calls == 1) return ['f1'];
          return ['f2'];
        });
        when(
          () => notes.getNotes(any()),
        ).thenAnswer((_) async => const Right<Failure, List<NoteEntity>>([]));
      },
      act: (cubit) async {
        await cubit.loadNotes();
        await cubit.loadNotes();
      },
      expect: () => [
        isA<NotesLoading>(),
        isA<NotesLoaded>(),
        isA<NotesLoading>(),
        isA<NotesLoaded>(),
      ],
      verify: (_) {
        verify(() => people.getFamilyIdsForUser('u1')).called(2);
        verify(() => notes.getNotes('f1')).called(1);
        verify(() => notes.getNotes('f2')).called(1);
      },
    );
  });

  group('NotesCubit.createNote', () {
    blocTest<NotesCubit, NotesState>(
      'success → NoteActionSuccess + reload',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => notes.createNote(any(), 'f1'),
        ).thenAnswer((_) async => const Right('new-id'));
        when(
          () => notes.getNotes('f1'),
        ).thenAnswer((_) async => Right<Failure, List<NoteEntity>>([note()]));
      },
      act: (cubit) => cubit.createNote(title: 'T', content: 'C', color: 'pink'),
      expect: () => [
        isA<NotesLoading>(),
        isA<NoteActionSuccess>(),
        isA<NotesLoading>(),
        isA<NotesLoaded>(),
      ],
    );

    blocTest<NotesCubit, NotesState>(
      'failure → NotesFailure',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => notes.createNote(any(), 'f1'),
        ).thenAnswer((_) async => Left(Failure(message: 'boom')));
      },
      act: (cubit) => cubit.createNote(title: 'T', content: 'C', color: 'pink'),
      expect: () => [isA<NotesLoading>(), isA<NotesFailure>()],
    );

    blocTest<NotesCubit, NotesState>(
      'no family → no-family NotesFailure',
      build: buildCubit,
      setUp: () {
        when(() => auth.currentUserId).thenReturn('u1');
        when(
          () => people.getFamilyIdsForUser('u1'),
        ).thenAnswer((_) async => <String>[]);
      },
      act: (cubit) => cubit.createNote(title: 'T', content: 'C', color: 'pink'),
      expect: () => [isA<NotesLoading>(), isA<NotesFailure>()],
      verify: (cubit) {
        expect((cubit.state as NotesFailure).message, notesFailureNoFamily);
      },
    );
  });

  group('NotesCubit.updateNote', () {
    blocTest<NotesCubit, NotesState>(
      'success → NoteActionSuccess + reload',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => notes.updateNote(any()),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => notes.getNotes('f1'),
        ).thenAnswer((_) async => Right<Failure, List<NoteEntity>>([note()]));
      },
      act: (cubit) => cubit.updateNote(
        note: note(),
        title: 'N',
        content: 'C',
        color: 'blue',
      ),
      expect: () => [
        isA<NotesLoading>(),
        isA<NoteActionSuccess>(),
        isA<NotesLoading>(),
        isA<NotesLoaded>(),
      ],
    );

    blocTest<NotesCubit, NotesState>(
      'stale id → NotesFailure + reload',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => notes.updateNote(any()),
        ).thenAnswer((_) async => Left(Failure(message: 'not-found')));
        when(
          () => notes.getNotes('f1'),
        ).thenAnswer((_) async => const Right<Failure, List<NoteEntity>>([]));
      },
      act: (cubit) => cubit.updateNote(
        note: note(),
        title: 'N',
        content: 'C',
        color: 'blue',
      ),
      expect: () => [
        isA<NotesLoading>(),
        isA<NotesFailure>(),
        isA<NotesLoading>(),
        isA<NotesLoaded>(),
      ],
      verify: (cubit) {
        expect(cubit.state, isA<NotesLoaded>());
      },
    );
  });

  group('NotesCubit.deleteNote', () {
    blocTest<NotesCubit, NotesState>(
      'success → NoteActionSuccess + reload',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => notes.deleteNote('n1'),
        ).thenAnswer((_) async => const Right(true));
        when(() => notes.getNotes(any())).thenAnswer(
          (_) async => Right<Failure, List<NoteEntity>>([note(id: 'n2')]),
        );
      },
      act: (cubit) => cubit.deleteNote('n1'),
      expect: () => [
        isA<NotesLoading>(),
        isA<NoteActionSuccess>(),
        isA<NotesLoading>(),
        isA<NotesLoaded>(),
      ],
      verify: (cubit) {
        expect((cubit.state as NotesLoaded).notes.map((n) => n.id), ['n2']);
      },
    );

    blocTest<NotesCubit, NotesState>(
      'failure → NotesFailure + reload',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => notes.deleteNote('n1'),
        ).thenAnswer((_) async => Left(Failure(message: 'boom')));
        when(
          () => notes.getNotes('f1'),
        ).thenAnswer((_) async => const Right<Failure, List<NoteEntity>>([]));
      },
      act: (cubit) => cubit.deleteNote('n1'),
      expect: () => [
        isA<NotesLoading>(),
        isA<NotesFailure>(),
        isA<NotesLoading>(),
        isA<NotesLoaded>(),
      ],
    );
  });

  group('NotesCubit free-tier limit', () {
    List<NoteEntity> rows(int count) =>
        List.generate(count, (i) => note(id: 'n$i'));

    blocTest<NotesCubit, NotesState>(
      'free user at 3 notes → limit-reached failure, no create call',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => subscriptions.isPro(userId: any(named: 'userId')),
        ).thenAnswer((_) async => false);
        when(
          () => notes.getNotesCount('f1'),
        ).thenAnswer((_) async => const Right<Failure, int>(3));
        when(
          () => notes.getNotes('f1'),
        ).thenAnswer((_) async => Right<Failure, List<NoteEntity>>(rows(3)));
      },
      act: (cubit) => cubit.createNote(title: 'T', content: 'C', color: 'pink'),
      expect: () => [isA<NotesLoading>(), isA<NotesLimitReached>()],
      verify: (cubit) {
        final state = cubit.state as NotesLimitReached;
        expect(state.notes, hasLength(3));
        verifyNever(() => notes.createNote(any(), any()));
      },
    );

    blocTest<NotesCubit, NotesState>(
      'limit-path reload failure preserves the underlying error',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => subscriptions.isPro(userId: any(named: 'userId')),
        ).thenAnswer((_) async => false);
        when(
          () => notes.getNotesCount('f1'),
        ).thenAnswer((_) async => const Right<Failure, int>(3));
        when(
          () => notes.getNotes('f1'),
        ).thenAnswer((_) async => Left(Failure(message: notesFailureOffline)));
      },
      act: (cubit) => cubit.createNote(title: 'T', content: 'C', color: 'pink'),
      expect: () => [isA<NotesLoading>(), isA<NotesFailure>()],
      verify: (cubit) {
        expect((cubit.state as NotesFailure).message, notesFailureOffline);
        verifyNever(() => notes.createNote(any(), any()));
      },
    );

    blocTest<NotesCubit, NotesState>(
      'free user below the cap creates normally',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => subscriptions.isPro(userId: any(named: 'userId')),
        ).thenAnswer((_) async => false);
        when(
          () => notes.getNotesCount('f1'),
        ).thenAnswer((_) async => const Right<Failure, int>(2));
        when(
          () => notes.getNotes('f1'),
        ).thenAnswer((_) async => Right<Failure, List<NoteEntity>>(rows(2)));
        when(
          () => notes.createNote(any(), 'f1'),
        ).thenAnswer((_) async => const Right('new-id'));
      },
      act: (cubit) => cubit.createNote(title: 'T', content: 'C', color: 'pink'),
      expect: () => [
        isA<NotesLoading>(),
        isA<NoteActionSuccess>(),
        isA<NotesLoading>(),
        isA<NotesLoaded>(),
      ],
    );

    blocTest<NotesCubit, NotesState>(
      'paid user above the cap creates normally',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => subscriptions.isPro(userId: any(named: 'userId')),
        ).thenAnswer((_) async => true);
        when(
          () => notes.createNote(any(), 'f1'),
        ).thenAnswer((_) async => const Right('new-id'));
        when(
          () => notes.getNotes('f1'),
        ).thenAnswer((_) async => Right<Failure, List<NoteEntity>>(rows(9)));
      },
      act: (cubit) => cubit.createNote(title: 'T', content: 'C', color: 'pink'),
      expect: () => [
        isA<NotesLoading>(),
        isA<NoteActionSuccess>(),
        isA<NotesLoading>(),
        isA<NotesLoaded>(),
      ],
      verify: (cubit) {
        expect((cubit.state as NotesLoaded).notes, hasLength(9));
      },
    );

    blocTest<NotesCubit, NotesState>(
      'count lookup failure fails open (create proceeds)',
      build: buildCubit,
      setUp: () {
        stubFamily();
        when(
          () => subscriptions.isPro(userId: any(named: 'userId')),
        ).thenAnswer((_) async => false);
        // Limit check fails, the post-create reload succeeds.
        when(
          () => notes.getNotesCount('f1'),
        ).thenAnswer((_) async => Left(Failure(message: 'offline')));
        when(
          () => notes.getNotes('f1'),
        ).thenAnswer((_) async => Right<Failure, List<NoteEntity>>([note()]));
        when(
          () => notes.createNote(any(), 'f1'),
        ).thenAnswer((_) async => const Right('new-id'));
      },
      act: (cubit) => cubit.createNote(title: 'T', content: 'C', color: 'pink'),
      expect: () => [
        isA<NotesLoading>(),
        isA<NoteActionSuccess>(),
        isA<NotesLoading>(),
        isA<NotesLoaded>(),
      ],
      verify: (_) {
        verify(() => notes.createNote(any(), 'f1')).called(1);
      },
    );

    test('isAtFreeLimit true at cap, false when paid or below cap', () async {
      stubFamily();
      when(
        () => subscriptions.isPro(userId: any(named: 'userId')),
      ).thenAnswer((_) async => false);
      when(
        () => notes.getNotesCount('f1'),
      ).thenAnswer((_) async => const Right<Failure, int>(3));
      final cubit = buildCubit();
      addTearDown(cubit.close);
      expect(await cubit.isAtFreeLimit(), isTrue);

      when(
        () => notes.getNotesCount('f1'),
      ).thenAnswer((_) async => const Right<Failure, int>(1));
      expect(await cubit.isAtFreeLimit(), isFalse);

      when(
        () => subscriptions.isPro(userId: any(named: 'userId')),
      ).thenAnswer((_) async => true);
      when(
        () => notes.getNotesCount('f1'),
      ).thenAnswer((_) async => const Right<Failure, int>(30));
      expect(await cubit.isAtFreeLimit(), isFalse);
    });

    test('isAtFreeLimit false without a family', () async {
      when(() => auth.currentUserId).thenReturn('u1');
      when(
        () => people.getFamilyIdsForUser('u1'),
      ).thenAnswer((_) async => <String>[]);
      when(
        () => subscriptions.isPro(userId: any(named: 'userId')),
      ).thenAnswer((_) async => false);
      final cubit = buildCubit();
      addTearDown(cubit.close);
      expect(await cubit.isAtFreeLimit(), isFalse);
    });
  });

  group('NotesCubit.hasFamily', () {
    test('true when a family resolves', () async {
      stubFamily();
      expect(await buildCubit().hasFamily(), isTrue);
    });

    test('false when resolution throws', () async {
      when(() => auth.currentUserId).thenReturn('u1');
      when(
        () => people.getFamilyIdsForUser('u1'),
      ).thenThrow(Exception('db down'));
      expect(await buildCubit().hasFamily(), isFalse);
    });
  });
}
