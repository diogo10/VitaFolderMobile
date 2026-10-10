import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira_core/auth/auth_service.dart';
import 'package:house_mira_core/errors/failure.dart';
import 'package:house_mira_core/subscriptions/subscription_service.dart';
import 'package:house_mira_core/subscriptions/usage_limits.dart';
import 'package:house_mira_core/widgets/sand/sand_primary_button.dart';
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
import 'package:house_mira_notes/presentation/widgets/notes_empty_widget.dart';
import 'package:house_mira_people/domain/entities/family_entity.dart';
import 'package:house_mira_people/domain/entities/person_entity.dart';
import 'package:house_mira_people/domain/repository/people_repository.dart';
import 'package:house_mira_core/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotes extends Mock implements NotesRepository {}

class _MockPeople extends Mock implements PeopleRepository {}

class _MockAuth extends Mock implements AuthService {}

/// Paid by default so existing tests exercise the uncapped path.
class _PaidSubscriptions extends SubscriptionService {
  @override
  Future<bool> isPro({String? userId}) async => true;
}

/// Free tier for limit-gate widget tests.
class _FreeSubscriptions extends SubscriptionService {
  @override
  Future<bool> isPro({String? userId}) async => false;
}

NoteEntity note({
  String id = 'n1',
  String title = 'Title',
  String content = 'Body text',
  String color = 'yellow',
}) {
  final now = DateTime.utc(2026);
  return NoteEntity(
    id: id,
    familyId: 'f1',
    createdBy: 'u1',
    title: title,
    content: content,
    color: color,
    createdAt: now,
    updatedAt: now,
  );
}

NotesCubit buildCubit({
  required NotesRepository notes,
  required PeopleRepository people,
  required AuthService auth,
  SubscriptionService? subscriptions,
}) => NotesCubit(
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
    subscriptionService: subscriptions ?? _PaidSubscriptions(),
    notesRepository: notes,
  ),
);

Widget pumpWithCubit(NotesCubit cubit, Widget child, {Locale? locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<NotesCubit>.value(value: cubit, child: child),
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

  void stubSignedIn({List<NoteEntity>? rows}) {
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
    if (rows != null) {
      when(() => notes.getNotes('f1')).thenAnswer(
        (_) async => Right<Failure, List<NoteEntity>>(rows),
      );
      when(() => notes.getNotesCount('f1')).thenAnswer(
        (_) async => Right<Failure, int>(rows.length),
      );
    }
  }

  group('NotesView smoke', () {
    testWidgets('EN: populated list shows heading and cards', (tester) async {
      stubSignedIn(rows: [note()]);
      final cubit = buildCubit(notes: notes, people: people, auth: auth);

      await tester.pumpWidget(pumpWithCubit(cubit, const NotesView()));
      await tester.pumpAndSettle();

      expect(find.byType(NoteCardWidget), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.textContaining('Smith Family'), findsOneWidget);
      await cubit.close();
    });

    testWidgets('PT: populated list shows cards', (tester) async {
      stubSignedIn(rows: [note()]);
      final cubit = buildCubit(notes: notes, people: people, auth: auth);

      await tester.pumpWidget(
        pumpWithCubit(cubit, const NotesView(), locale: const Locale('pt')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NoteCardWidget), findsOneWidget);
      expect(find.text('Notas'), findsOneWidget);
      await cubit.close();
    });

    testWidgets('empty state with create CTA', (tester) async {
      stubSignedIn(rows: const []);
      final cubit = buildCubit(notes: notes, people: people, auth: auth);

      await tester.pumpWidget(pumpWithCubit(cubit, const NotesView()));
      await tester.pumpAndSettle();

      expect(find.byType(NotesEmptyWidget), findsOneWidget);
      expect(find.text('Create Your First Note'), findsOneWidget);
      await cubit.close();
    });

    testWidgets('unauthenticated state with sign-in actions', (tester) async {
      when(() => auth.isLoggedIn()).thenReturn(false);
      when(() => auth.currentUserId).thenReturn(null);
      final cubit = buildCubit(notes: notes, people: people, auth: auth);

      await tester.pumpWidget(pumpWithCubit(cubit, const NotesView()));
      await tester.pumpAndSettle();

      expect(find.text('Shared Notes'), findsOneWidget);
      expect(find.text('Sign In to Start'), findsOneWidget);
      expect(find.text('Join a Family'), findsOneWidget);
      await cubit.close();
    });

    testWidgets('failure codes render localized messages', (tester) async {
      stubSignedIn();
      when(() => notes.getNotes('f1')).thenAnswer(
        (_) async => Left(Failure(message: 'not-found')),
      );
      final cubit = buildCubit(notes: notes, people: people, auth: auth);

      await tester.pumpWidget(pumpWithCubit(cubit, const NotesView()));
      await tester.pumpAndSettle();

      expect(find.text('Note not found'), findsOneWidget);
      await cubit.close();
    });

    testWidgets('offline failure renders localized message', (tester) async {
      stubSignedIn();
      when(() => notes.getNotes('f1')).thenAnswer(
        (_) async => Left(Failure(message: 'offline')),
      );
      final cubit = buildCubit(notes: notes, people: people, auth: auth);

      await tester.pumpWidget(pumpWithCubit(cubit, const NotesView()));
      await tester.pumpAndSettle();

      expect(find.text('You appear to be offline'), findsOneWidget);
      await cubit.close();
    });
  });

  group('NoteEditorScreen', () {
    testWidgets('whitespace-only shows inline errors, no save', (
      tester,
    ) async {
      when(() => auth.currentUserId).thenReturn('u1');
      final cubit = buildCubit(notes: notes, people: people, auth: auth);

      await tester.pumpWidget(pumpWithCubit(cubit, const NoteEditorScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), '   ');
      await tester.enterText(find.byType(TextFormField).at(1), '   ');
      await tester.pump();
      await tester.tap(find.byType(SandPrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text('Enter a title'), findsOneWidget);
      expect(find.text('Enter some content'), findsOneWidget);
      verifyNever(() => notes.createNote(any(), any()));
      await cubit.close();
    });

    testWidgets('over-limit shows too-long errors', (tester) async {
      when(() => auth.currentUserId).thenReturn('u1');
      final cubit = buildCubit(notes: notes, people: people, auth: auth);

      await tester.pumpWidget(pumpWithCubit(cubit, const NoteEditorScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'a' * 101);
      await tester.enterText(find.byType(TextFormField).at(1), 'b' * 301);
      await tester.pump();
      await tester.tap(find.byType(SandPrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text('Title must be at most 100 characters'), findsOneWidget);
      expect(
        find.text('Content must be at most 300 characters'),
        findsOneWidget,
      );
      verifyNever(() => notes.createNote(any(), any()));
      await cubit.close();
    });

    testWidgets('valid save wires createNote', (tester) async {
      when(() => auth.currentUserId).thenReturn('u1');
      when(
        () => people.getFamilyIdsForUser('u1'),
      ).thenAnswer((_) async => ['f1']);
      when(() => notes.createNote(any(), 'f1')).thenAnswer(
        (_) async => const Right('new-id'),
      );
      when(() => notes.getNotes('f1')).thenAnswer(
        (_) async => const Right<Failure, List<NoteEntity>>([]),
      );
      when(() => people.getMyFamily()).thenAnswer(
        (_) async => Right<Exception, FamilyEntity>(
          FamilyEntity(name: 'Smith Family', inviteCode: 'ABC'),
        ),
      );
      when(
        () => people.getProfilesWithRoleForFamily(any()),
      ).thenAnswer((_) async => const <PersonEntity>[]);
      final cubit = buildCubit(notes: notes, people: people, auth: auth);
      var saved = false;

      await tester.pumpWidget(
        pumpWithCubit(cubit, NoteEditorScreen(onSaved: () => saved = true)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Hello');
      await tester.enterText(find.byType(TextFormField).at(1), 'World');
      await tester.pump();
      await tester.tap(find.byType(SandPrimaryButton));
      await tester.pumpAndSettle();

      expect(saved, isTrue);
      verify(() => notes.createNote(any(), 'f1')).called(1);
      await cubit.close();
    });

    testWidgets('successful save returns to the previous screen', (
      tester,
    ) async {
      when(() => auth.currentUserId).thenReturn('u1');
      when(
        () => people.getFamilyIdsForUser('u1'),
      ).thenAnswer((_) async => ['f1']);
      when(() => notes.createNote(any(), 'f1')).thenAnswer(
        (_) async => const Right('new-id'),
      );
      when(() => notes.getNotes('f1')).thenAnswer(
        (_) async => const Right<Failure, List<NoteEntity>>([]),
      );
      when(() => people.getMyFamily()).thenAnswer(
        (_) async => Right<Exception, FamilyEntity>(
          FamilyEntity(name: 'Smith Family', inviteCode: 'ABC'),
        ),
      );
      when(
        () => people.getProfilesWithRoleForFamily(any()),
      ).thenAnswer((_) async => const <PersonEntity>[]);
      final cubit = buildCubit(notes: notes, people: people, auth: auth);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<NotesCubit>.value(
            value: cubit,
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => BlocProvider<NotesCubit>.value(
                          value: cubit,
                          child: const NoteEditorScreen(),
                        ),
                      ),
                    ),
                    child: const Text('open editor'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open editor'));
      await tester.pumpAndSettle();
      expect(find.text('New Note'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Hello');
      await tester.enterText(find.byType(TextFormField).at(1), 'World');
      await tester.pump();
      await tester.tap(find.byType(SandPrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text('open editor'), findsOneWidget);
      expect(find.text('New Note'), findsNothing);
      await cubit.close();
    });

    testWidgets('edit pre-populates title and content', (tester) async {
      when(() => auth.currentUserId).thenReturn('u1');
      final cubit = buildCubit(notes: notes, people: people, auth: auth);

      await tester.pumpWidget(
        pumpWithCubit(
          cubit,
          NoteEditorScreen(
            note: note(title: 'Pre', content: 'Populated'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pre'), findsOneWidget);
      expect(find.text('Populated'), findsOneWidget);
      expect(find.text('Edit Note'), findsOneWidget);
      await cubit.close();
    });

    testWidgets('toolbar has exactly two buttons (bold, list)', (
      tester,
    ) async {
      when(() => auth.currentUserId).thenReturn('u1');
      final cubit = buildCubit(notes: notes, people: people, auth: auth);

      await tester.pumpWidget(pumpWithCubit(cubit, const NoteEditorScreen()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.format_bold_rounded), findsOneWidget);
      expect(find.byIcon(Icons.format_list_bulleted_rounded), findsOneWidget);
      await cubit.close();
    });
  });

  group('Delete dialog wiring', () {
    testWidgets('confirm calls deleteNote; cancel does not', (tester) async {
      stubSignedIn(rows: [note()]);
      when(() => notes.deleteNote('n1')).thenAnswer(
        (_) async => const Right(true),
      );
      final cubit = buildCubit(notes: notes, people: people, auth: auth);

      await tester.pumpWidget(pumpWithCubit(cubit, const NotesView()));
      await tester.pumpAndSettle();

      // Open bottom sheet.
      await tester.tap(find.byType(NoteCardWidget));
      await tester.pumpAndSettle();
      expect(find.text('Remove'), findsWidgets);

      // Tap Remove → confirm dialog.
      await tester.tap(find.text('Remove').last);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // Confirm.
      await tester.tap(find.text('Remove').last);
      await tester.pumpAndSettle();
      verify(() => notes.deleteNote('n1')).called(1);
      await cubit.close();
    });

    testWidgets('dialog cancel leaves the list unchanged', (tester) async {
      stubSignedIn(rows: [note()]);
      final cubit = buildCubit(notes: notes, people: people, auth: auth);

      await tester.pumpWidget(pumpWithCubit(cubit, const NotesView()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(NoteCardWidget));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove').last);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => notes.deleteNote(any()));
      expect(find.byType(NoteCardWidget), findsOneWidget);
      await cubit.close();
    });
  });

  group('FR-110 overflow', () {
    for (final locale in [const Locale('en'), const Locale('pt')]) {
      testWidgets(
        'long strings render overflow-free (${locale.languageCode})',
        (tester) async {
          stubSignedIn(
            rows: [
              note(title: 'A very long title ' * 10, content: 'Body ' * 40),
            ],
          );
          final cubit = buildCubit(notes: notes, people: people, auth: auth);

          await tester.pumpWidget(
            pumpWithCubit(cubit, const NotesView(), locale: locale),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(NoteCardWidget), findsOneWidget);
          await cubit.close();
        },
      );
    }
  });

  group('Markdown render', () {
    testWidgets('bold spans, bullet rows, plain passthrough', (tester) async {
      stubSignedIn(
        rows: [note(content: 'Hello **bold** world\n- item one\nplain')],
      );
      final cubit = buildCubit(notes: notes, people: people, auth: auth);

      await tester.pumpWidget(pumpWithCubit(cubit, const NotesView()));
      await tester.pumpAndSettle();

      // Text.rich splits content into spans, so assert on the span tree
      // rather than flattened text.
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final allText = richTexts.map((r) => r.text.toPlainText()).join('\n');
      expect(allText, contains('bold'));
      expect(allText, contains('item one'));
      expect(allText, contains('plain'));
      // Bold segment carries w700.
      var foundBold = false;
      void visit(InlineSpan span) {
        if (span is TextSpan) {
          if (span.text == 'bold' &&
              span.style?.fontWeight == FontWeight.w700) {
            foundBold = true;
          }
          (span.children ?? const <InlineSpan>[]).forEach(visit);
        }
      }

      richTexts.map((r) => r.text).forEach(visit);
      expect(foundBold, isTrue);
      await cubit.close();
    });
  });

  group('Free-tier limit gate', () {
    testWidgets('free user at cap sees the limit message on add', (
      tester,
    ) async {
      final rows = List.generate(3, (i) => note(id: 'n$i'));
      stubSignedIn(rows: rows);
      final cubit = buildCubit(
        notes: notes,
        people: people,
        auth: auth,
        subscriptions: _FreeSubscriptions(),
      );
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => BlocProvider<NotesCubit>.value(
              value: cubit,
              child: const NotesView(),
            ),
          ),
          GoRoute(
            path: '/paywall',
            builder: (_, _) => const Scaffold(body: Text('paywall-marker')),
          ),
        ],
      );
      addTearDown(() async {
        router.dispose();
        await cubit.close();
      });
      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // The add gate resolves the family once and reuses it for the limit
      // check (single lookup, not one per check).
      clearInteractions(people);
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      final l = AppLocalizations.of(tester.element(find.byType(NotesView)))!;
      expect(
        find.text(l.notesErrorLimitReached(UsageLimits.freeNotesLimit)),
        findsOneWidget,
      );
      expect(find.text(l.limitReachedUpgrade), findsOneWidget);
      // The editor never opens: no editor title appears.
      expect(find.text(l.notesCreateTitle), findsNothing);
      verify(() => people.getFamilyIdsForUser('u1')).called(1);

      await tester.tap(find.text(l.limitReachedUpgrade));
      await tester.pumpAndSettle();
      expect(find.text('paywall-marker'), findsOneWidget);
    });

    testWidgets('limit state surfaces an in-list upgrade banner', (
      tester,
    ) async {
      final rows = List.generate(3, (i) => note(id: 'n$i'));
      stubSignedIn(rows: rows);
      final cubit = buildCubit(
        notes: notes,
        people: people,
        auth: auth,
        subscriptions: _FreeSubscriptions(),
      );
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => BlocProvider<NotesCubit>.value(
              value: cubit,
              child: const NotesView(),
            ),
          ),
          GoRoute(
            path: '/paywall',
            builder: (_, _) => const Scaffold(body: Text('paywall-marker')),
          ),
        ],
      );
      addTearDown(() async {
        router.dispose();
        await cubit.close();
      });
      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // A capped create lands the list in NotesLimitReached (list kept).
      await cubit.createNote(title: 'T', content: 'C', color: 'yellow');
      await tester.pumpAndSettle();

      final l = AppLocalizations.of(tester.element(find.byType(NotesView)))!;
      expect(
        find.text(l.notesErrorLimitReached(UsageLimits.freeNotesLimit)),
        findsOneWidget,
      );
      expect(find.text(l.limitReachedUpgrade), findsOneWidget);
      expect(find.byType(NoteCardWidget), findsNWidgets(3));

      await tester.tap(find.text(l.limitReachedUpgrade));
      await tester.pumpAndSettle();
      expect(find.text('paywall-marker'), findsOneWidget);
    });
  });
}
