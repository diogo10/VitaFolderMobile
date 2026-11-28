import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira_core/auth/auth_service.dart';
import 'package:house_mira_core/config/remote_config_service.dart';
import 'package:house_mira_core/errors/failure.dart';
import 'package:house_mira_core/generated/app_localizations.dart';
import 'package:house_mira_core/observability/app_logger.dart';
import 'package:house_mira_core/subscriptions/subscription_service.dart';
import 'package:house_mira_notes/application/is_at_note_limit_usecase.dart';
import 'package:house_mira_notes/data/models/note_model.dart';
import 'package:house_mira_notes/domain/entities/note_entity.dart';
import 'package:house_mira_notes/domain/repository/notes_repository.dart';
import 'package:house_mira_notes/domain/usecase/create_note_usecase.dart';
import 'package:house_mira_notes/domain/usecase/delete_note_usecase.dart';
import 'package:house_mira_notes/domain/usecase/get_notes_usecase.dart';
import 'package:house_mira_notes/domain/usecase/update_note_usecase.dart';
import 'package:house_mira_notes/presentation/cubit/notes_cubit.dart';
import 'package:house_mira_notes/presentation/views/note_editor_screen.dart';
import 'package:house_mira_notes/presentation/views/notes_view.dart';
import 'package:house_mira_notes/presentation/widgets/note_card_widget.dart';
import 'package:house_mira_people/domain/entities/family_entity.dart';
import 'package:house_mira_people/domain/entities/person_entity.dart';
import 'package:house_mira_people/domain/repository/people_repository.dart';
import 'package:mocktail/mocktail.dart';

/// Pins the semantics identifiers the device e2e suite locates by
/// (`e2e/tests/notes.e2e.ts`). Renaming or dropping one fails there on a real
/// emulator with a much slower feedback loop, so it is pinned here first.
class _MockNotes extends Mock implements NotesRepository {}

class _MockPeople extends Mock implements PeopleRepository {}

class _MockAuth extends Mock implements AuthService {}

class _MockRemoteConfig extends Mock implements FirebaseRemoteConfig {}

/// Uncapped by default: these tests are about locators, not the paywall.
class _PaidSubscriptions extends SubscriptionService {
  @override
  Future<bool> isPro({String? userId}) async => true;
}

NoteEntity _note() {
  final now = DateTime.utc(2026);
  return NoteEntity(
    id: 'n1',
    familyId: 'f1',
    createdBy: 'u1',
    title: 'Pinned note',
    content: 'Body text',
    color: 'yellow',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late _MockNotes notes;
  late _MockPeople people;
  late _MockAuth auth;

  setUp(() {
    notes = _MockNotes();
    people = _MockPeople();
    auth = _MockAuth();
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

  NotesCubit buildCubit() {
    final remoteConfig = _MockRemoteConfig();
    when(
      () => remoteConfig.getBool('enable_limit_and_paywall'),
    ).thenReturn(true);
    return NotesCubit(
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
        subscriptionService: _PaidSubscriptions(),
        notesRepository: notes,
        remoteConfigService: RemoteConfigService(
          remoteConfig: remoteConfig,
          logger: AppLogger(),
        ),
      ),
    );
  }

  void stubSignedIn() {
    when(() => auth.isLoggedIn()).thenReturn(true);
    when(() => auth.currentUserId).thenReturn('u1');
    when(
      () => people.getFamilyIdsForUser('u1'),
    ).thenAnswer((_) async => ['f1']);
    when(() => people.getMyFamily()).thenAnswer(
      (_) async => Right<Exception, FamilyEntity>(
        FamilyEntity(name: 'Smith Family', inviteCode: 'ABC'),
      ),
    );
    when(
      () => people.getProfilesWithRoleForFamily(any()),
    ).thenAnswer((_) async => const <PersonEntity>[]);
    when(() => notes.getNotes('f1')).thenAnswer(
      (_) async => Right<Failure, List<NoteEntity>>([_note()]),
    );
    when(() => notes.getNotesCount('f1')).thenAnswer(
      (_) async => const Right<Failure, int>(1),
    );
    when(() => notes.deleteNote('n1')).thenAnswer(
      (_) async => const Right(true),
    );
  }

  Widget pumpWithCubit(NotesCubit cubit, Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<NotesCubit>.value(value: cubit, child: child),
    );
  }

  Future<void> withSemantics(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await body();
    } finally {
      handle.dispose();
    }
  }

  group('NotesView semantics identifiers', () {
    testWidgets('list exposes add, loaded and card identifiers', (
      tester,
    ) async {
      await withSemantics(tester, () async {
        stubSignedIn();
        final cubit = buildCubit();
        addTearDown(cubit.close);

        await tester.pumpWidget(pumpWithCubit(cubit, const NotesView()));
        await tester.pumpAndSettle();

        expect(
          find.bySemanticsIdentifier('notes-add-button'),
          findsOneWidget,
        );
        expect(find.bySemanticsIdentifier('notes-loaded'), findsOneWidget);
        expect(
          find.bySemanticsIdentifier('note-card-n1'),
          findsOneWidget,
        );
      });
    });

    testWidgets('card menu and delete dialog expose identifiers', (
      tester,
    ) async {
      await withSemantics(tester, () async {
        stubSignedIn();
        final cubit = buildCubit();
        addTearDown(cubit.close);

        await tester.pumpWidget(pumpWithCubit(cubit, const NotesView()));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(NoteCardWidget));
        await tester.pumpAndSettle();
        expect(find.bySemanticsIdentifier('note-menu-edit'), findsOneWidget);
        expect(
          find.bySemanticsIdentifier('note-menu-remove'),
          findsOneWidget,
        );

        await tester.tap(find.bySemanticsIdentifier('note-menu-remove'));
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsIdentifier('note-delete-confirm'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsIdentifier('note-delete-cancel'),
          findsOneWidget,
        );
      });
    });
  });

  group('NoteEditorScreen semantics identifiers', () {
    testWidgets('title, content and save expose identifiers', (tester) async {
      await withSemantics(tester, () async {
        when(() => auth.currentUserId).thenReturn('u1');
        final cubit = buildCubit();
        addTearDown(cubit.close);

        await tester.pumpWidget(
          pumpWithCubit(cubit, const NoteEditorScreen()),
        );
        await tester.pumpAndSettle();

        final title = find.bySemanticsIdentifier('note-editor-title');
        final content = find.bySemanticsIdentifier('note-editor-content');
        final save = find.bySemanticsIdentifier('note-editor-save');

        expect(title, findsOneWidget);
        expect(content, findsOneWidget);
        expect(save, findsOneWidget);

        expect(
          tester
              .getSemantics(title)
              .getSemanticsData()
              .flagsCollection
              .isTextField,
          isTrue,
        );
        expect(
          tester
              .getSemantics(content)
              .getSemanticsData()
              .flagsCollection
              .isTextField,
          isTrue,
        );
        expect(
          tester.getSemantics(save).getSemanticsData().flagsCollection.isButton,
          isTrue,
        );
      });
    });
  });
}
