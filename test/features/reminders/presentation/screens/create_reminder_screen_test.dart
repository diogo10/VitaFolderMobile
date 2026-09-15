import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/reminders/data/models/reminder_model.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';
import 'package:house_mira/features/reminders/domain/usecase/create_reminder_usecase.dart';
import 'package:house_mira/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:house_mira/features/reminders/domain/usecase/update_reminder_usecase.dart';
import 'package:house_mira/features/reminders/presentation/cubit/create_reminder_cubit.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:house_mira/features/reminders/presentation/screens/create_reminder_screen.dart';
import 'package:house_mira/generated/app_localizations.dart';

class _FakeAuthService extends Mock implements AuthService {
  @override
  bool isLoggedIn() => true;

  @override
  String? get currentUserId => 'fake-user-id';
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

      expect(find.text(reminder.title), findsOneWidget);
      expect(find.text(reminder.body), findsOneWidget);
      expect(find.text('22/8/2026'), findsOneWidget);
      expect(find.text('3:00 PM'), findsOneWidget);
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
      addTearDown(() {
        if (!completer.isCompleted) completer.complete(Right(true));
      });

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
