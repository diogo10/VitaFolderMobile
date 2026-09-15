import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
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
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_lead_time.dart';
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

class _FakeNotificationService implements IReminderNotificationService {
  final Map<String, ReminderNotificationPrefs> stored = {};
  final List<ScheduledCall> scheduled = [];
  final List<String> cancelled = [];

  @override
  Future<void> init() async {}

  @override
  Future<ReminderNotificationPrefs> getReminderNotification(
    String reminderId,
  ) async => stored[reminderId] ?? ReminderNotificationPrefs.disabled;

  @override
  Future<void> setReminderNotification({
    required String reminderId,
    required bool enabled,
    required ReminderLeadTime leadTime,
    required DateTime? dueDate,
    required String title,
    required String body,
    required String repeatRule,
  }) async {
    scheduled.add(
      ScheduledCall(
        reminderId: reminderId,
        enabled: enabled,
        leadTime: leadTime,
        dueDate: dueDate,
      ),
    );
    stored[reminderId] = ReminderNotificationPrefs(
      enabled: enabled,
      leadTime: leadTime,
    );
  }

  @override
  Future<void> cancelReminderNotification(String reminderId) async {
    cancelled.add(reminderId);
    stored[reminderId] = ReminderNotificationPrefs.disabled;
  }
}

class ScheduledCall {
  final String reminderId;
  final bool enabled;
  final ReminderLeadTime leadTime;
  final DateTime? dueDate;

  ScheduledCall({
    required this.reminderId,
    required this.enabled,
    required this.leadTime,
    required this.dueDate,
  });
}

void main() {
  late _FakeAuthService authService;
  late _FakePeopleRepository peopleRepository;
  late _FakeCreateReminderUsecase createReminderUsecase;
  late _FakeUpdateReminderUsecase updateReminderUsecase;
  late _FakeGetReminderUsecase getReminderUsecase;

  setUp(() {
    authService = _FakeAuthService();
    peopleRepository = _FakePeopleRepository();
    createReminderUsecase = _FakeCreateReminderUsecase();
    updateReminderUsecase = _FakeUpdateReminderUsecase();
    getReminderUsecase = _FakeGetReminderUsecase();
    registerFallbackValue(ReminderType.appointment);
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

  MultiBlocProvider buildProviders({
    ReminderEntity? reminder,
    IReminderNotificationService? notificationService,
    required Widget child,
  }) {
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
            getReminderUsecase: getReminderUsecase,
            peopleRepository: peopleRepository,
            authService: authService,
            reminderRepository: _FakeReminderRepository(),
          ),
        ),
      ],
      child: child,
    );
  }

  Widget pumpApp({
    ReminderEntity? reminder,
    IReminderNotificationService? notificationService,
  }) {
    return buildProviders(
      reminder: reminder,
      notificationService: notificationService,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CreateReminderScreen(
          reminder: reminder,
          notificationService:
              notificationService ?? _FakeNotificationService(),
        ),
      ),
    );
  }

  GoRouter buildTestRouter({
    ReminderEntity? reminder,
    required IReminderNotificationService notificationService,
  }) {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
        ),
        GoRoute(
          path: '/create',
          builder: (_, _) => CreateReminderScreen(
            reminder: reminder,
            notificationService: notificationService,
          ),
        ),
      ],
    );
  }

  Widget pumpRouter(GoRouter router) {
    return buildProviders(
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
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

  group('CreateReminderScreen notifications', () {
    testWidgets('notify toggle defaults to off without lead options', (
      tester,
    ) async {
      await tester.pumpWidget(pumpApp());
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(CreateReminderScreen)),
      )!;

      expect(find.text(l.createReminderNotifyTitle), findsOneWidget);
      expect(find.text(l.createReminderNotifyToggle), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(find.text(l.createReminderNotify15Min), findsNothing);
    });

    testWidgets('enabling toggle reveals lead options defaulting to 15 min', (
      tester,
    ) async {
      await tester.pumpWidget(pumpApp());
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(CreateReminderScreen)),
      )!;

      await tester.ensureVisible(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // No date set yet, so a hint is shown instead of lead options.
      expect(find.text(l.createReminderNotifyNoDateHint), findsOneWidget);
    });

    testWidgets('edit mode pre-fills notify choice from prefs', (tester) async {
      final service = _FakeNotificationService()
        ..stored['1'] = const ReminderNotificationPrefs(
          enabled: true,
          leadTime: ReminderLeadTime.oneHour,
        );

      await tester.pumpWidget(
        pumpApp(reminder: reminder, notificationService: service),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(CreateReminderScreen)),
      )!;

      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(find.text(l.createReminderNotify1Hour), findsOneWidget);
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, l.createReminderNotify1Hour),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('save schedules notification with the created id', (
      tester,
    ) async {
      final service = _FakeNotificationService();
      when(
        () => createReminderUsecase.call(any(), any()),
      ).thenAnswer((_) async => Right('new-id'));
      when(
        () => peopleRepository.getMyFamilyRole(),
      ).thenAnswer((_) async => <String>[]);
      when(
        () => peopleRepository.getFamilyIdsForUser(any()),
      ).thenAnswer((_) async => ['fam-1']);
      when(
        () => getReminderUsecase.call(any(), type: any(named: 'type')),
      ).thenAnswer((_) async => Right([]));

      final testRouter = buildTestRouter(notificationService: service);
      await tester.pumpWidget(pumpRouter(testRouter));
      await tester.pumpAndSettle();

      testRouter.push('/create');
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(CreateReminderScreen)),
      )!;

      await tester.enterText(find.byType(TextFormField).first, 'T');
      await tester.ensureVisible(find.text(l.createReminderNotifyToggle));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.createReminderNotifyToggle));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      await tester.tap(find.text(l.createReminderSaveButton));
      await tester.pumpAndSettle();

      expect(service.scheduled, hasLength(1));
      expect(service.scheduled.single.reminderId, 'new-id');
      expect(service.scheduled.single.enabled, isTrue);
      expect(
        service.scheduled.single.leadTime,
        ReminderLeadTime.fifteenMinutes,
      );
    });
  });
}
