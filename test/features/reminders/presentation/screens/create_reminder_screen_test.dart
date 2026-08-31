import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/person_entity.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';
import 'package:vita_folder_mobile/features/reminders/data/models/reminder_model.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/domain/repository/reminder_repository.dart';
import 'package:vita_folder_mobile/features/reminders/domain/usecase/create_reminder_usecase.dart';
import 'package:vita_folder_mobile/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:vita_folder_mobile/features/reminders/domain/usecase/update_reminder_usecase.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/create_reminder_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/screens/create_reminder_screen.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class _FakeAuthService implements AuthService {
  @override
  User? get currentUser => null;

  @override
  bool isLoggedIn() => true;

  @override
  String? get currentUserId => 'fake-user-id';

  @override
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
  }) async => null;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> triggerForgetPassword({required String email}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> updateName(String name) async {}

  @override
  Future<String?> getProfileName() async => null;

  @override
  Future<PersonEntity?> getAsPersonEntity() async => null;
}

class _FakePeopleRepository extends Mock implements PeopleRepository {}

class _FakeCreateReminderUsecase extends Mock
    implements CreateReminderUsecase {}

class _FakeUpdateReminderUsecase extends Mock
    implements UpdateReminderUsecase {}

class _FakeGetReminderUsecase extends Mock implements GetReminderUsecase {}

class _FakeReminderRepository extends Mock implements ReminderRepository {}

void main() {
  late _FakeAuthService authService;
  late _FakePeopleRepository peopleRepository;
  late _FakeCreateReminderUsecase createReminderUsecase;
  late _FakeUpdateReminderUsecase updateReminderUsecase;

  setUp(() {
    authService = _FakeAuthService();
    peopleRepository = _FakePeopleRepository();
    createReminderUsecase = _FakeCreateReminderUsecase();
    updateReminderUsecase = _FakeUpdateReminderUsecase();
  });

  setUpAll(() {
    registerFallbackValue(
      ReminderModel(
        title: '',
        body: '',
        id: '',
        type: ReminderType.custom,
        dueDate: '',
        repeatRule: 'never',
        status: '',
        createdBy: '',
        createdAt: '',
      ),
    );
  });

  final reminder = ReminderEntity(
    id: '1',
    title: 'Test Title',
    body: 'Test Body',
    type: ReminderType.appointment,
    dueDate: '22/08/2026 15:00',
    repeatRule: 'weekly',
    status: 'pending',
    createdBy: 'Mom',
    createdAt: '2026-08-01',
  );

  Widget pumpApp({ReminderEntity? reminder}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CreateReminderCubit>(
          create: (_) => CreateReminderCubit(
            createReminderUsecase: createReminderUsecase,
            updateReminderUsecase: updateReminderUsecase,
            authService: authService,
            peopleRepository: peopleRepository,
          ),
        ),
        BlocProvider<RemindersCubit>(
          create: (_) => RemindersCubit(
            getReminderUsecase: _FakeGetReminderUsecase(),
            peopleRepository: peopleRepository,
            authService: authService,
            reminderRepository: _FakeReminderRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CreateReminderScreen(reminder: reminder),
      ),
    );
  }

  group('CreateReminderScreen in edit mode', () {
    testWidgets('pre-fills fields from the reminder', (tester) async {
      await tester.pumpWidget(pumpApp(reminder: reminder));
      final l = AppLocalizations.of(
        tester.element(find.byType(CreateReminderScreen)),
      )!;

      expect(find.text(reminder.title), findsOneWidget);
      expect(find.text(reminder.body), findsOneWidget);
      expect(
        find.text('${l.createReminderDueDateLabel}: 22/8/2026'),
        findsOneWidget,
      );
      expect(
        find.text('${l.createReminderTimeLabel}: 3:00 PM'),
        findsOneWidget,
      );
    });

    testWidgets('shows edit title and save label', (tester) async {
      await tester.pumpWidget(pumpApp(reminder: reminder));
      final l = AppLocalizations.of(
        tester.element(find.byType(CreateReminderScreen)),
      )!;

      expect(find.text(l.createReminderTitleEdit), findsOneWidget);
      expect(find.text(l.createReminderSaveButtonEdit), findsOneWidget);
    });

    testWidgets('save calls updateReminder with the existing id', (
      tester,
    ) async {
      final completer = Completer<Either<Failure, bool>>();
      when(
        () => updateReminderUsecase.call(any()),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(pumpApp(reminder: reminder));
      final l = AppLocalizations.of(
        tester.element(find.byType(CreateReminderScreen)),
      )!;

      await tester.tap(find.text(l.createReminderSaveButtonEdit));
      await tester.pump();

      final captured =
          verify(() => updateReminderUsecase.call(captureAny())).captured.single
              as ReminderModel;
      expect(captured.id, '1');
      expect(captured.title, 'Test Title');

      verifyNever(() => createReminderUsecase.call(any(), any()));
    });
  });
}
