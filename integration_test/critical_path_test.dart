import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:house_mira/core/analytics/analytics_service.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/auth/auth_state_notifier.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:house_mira/features/home/domain/usecase/has_reminders_usecase.dart';
import 'package:house_mira/features/home/presentation/cubit/home_cubit.dart';
import 'package:house_mira/features/home/presentation/views/home_view.dart';
import 'package:house_mira/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:house_mira/features/people/domain/entities/family_entity.dart';
import 'package:house_mira/features/people/domain/entities/people_data.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/people/domain/usecase/create_family_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/get_people_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/join_family_usecase.dart';
import 'package:house_mira/features/people/presentation/cubit/people_cubit.dart';
import 'package:house_mira/features/people/presentation/views/people_view.dart';
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_lead_time.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';
import 'package:house_mira/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:house_mira/features/reminders/presentation/screens/reminders_view.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/main.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

/// Critical-path integration test: onboarding → home → reminders → people.
///
/// Runs under `flutter test integration_test` (CI) and on-device via
/// `flutter test integration_test/critical_path_test.dart`. All backends are
/// faked: the goal is to pin the navigation contract (route table, tab order,
/// onboarding gate) so a router or shell refactor that breaks the journey
/// fails fast before reaching manual QA.
///
/// Startup budget: the home journey must settle within [startupBudget] on a
/// test host. Device budgets are enforced separately in CI
/// (`tool/performance_budgets.json` + build reporting).
const startupBudget = Duration(seconds: 15);

class _MockObserver extends Mock implements FirebaseAnalyticsObserver {}

class _FakeAnalyticsService extends Fake implements AnalyticsService {
  @override
  FirebaseAnalyticsObserver get observer => _MockObserver();
}

class _MockAuthService extends Mock implements AuthService {}

class _MockGetHomeDataUsecase extends Mock implements GetHomeDataUsecase {}

class _MockHasRemindersUsecase extends Mock implements HasRemindersUsecase {}

class _MockGetPeopleUsecase extends Mock implements GetPeopleUsecase {}

class _MockCreateFamilyUsecase extends Mock implements CreateFamilyUsecase {}

class _MockJoinFamilyUsecase extends Mock implements JoinFamilyUsecase {}

class _MockPeopleRepository extends Mock implements PeopleRepository {}

class _MockGetReminderUsecase extends Mock implements GetReminderUsecase {}

class _MockReminderRepository extends Mock implements ReminderRepository {}

class _FakeNotificationService implements IReminderNotificationService {
  final tapController = StreamController<String?>.broadcast();

  @override
  Future<void> init() async {}

  @override
  Stream<String?> get onNotificationTap => tapController.stream;

  @override
  Future<String?> getLaunchPayload() async => null;

  @override
  Future<bool> hasSystemPermission() async => false;

  @override
  Future<bool> requestSystemPermission() async => false;

  @override
  Future<bool> canScheduleExactAlarms() async => true;

  @override
  Future<void> requestExactAlarmPermission() async {}

  @override
  Future<ReminderNotificationPrefs> getReminderNotification(
    String reminderId,
  ) async => ReminderNotificationPrefs.disabled;

  @override
  Future<bool> setReminderNotification({
    required String reminderId,
    required bool enabled,
    required ReminderLeadTime leadTime,
    required DateTime? dueDate,
    required String title,
    required String body,
    required String repeatRule,
  }) async => true;

  @override
  Future<void> cancelReminderNotification(String reminderId) async {}

  @override
  Future<bool> showTestNotification({
    required String title,
    required String body,
  }) async => true;

  @override
  Future<void> rescheduleAll(List<ReminderEntity> reminders) async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthService authService;
  late _MockPeopleRepository peopleRepository;
  late _MockGetReminderUsecase getReminderUsecase;
  late _MockGetPeopleUsecase getPeopleUsecase;
  late _FakeNotificationService notifications;

  setUpAll(() {
    registerFallbackValue(ReminderType.custom);
  });

  setUp(() async {
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<AnalyticsService>(
      _FakeAnalyticsService(),
      instanceName: 'analyticsService',
    );

    authService = _MockAuthService();
    peopleRepository = _MockPeopleRepository();
    getReminderUsecase = _MockGetReminderUsecase();
    getPeopleUsecase = _MockGetPeopleUsecase();
    notifications = _FakeNotificationService();
    addTearDown(notifications.tapController.close);

    when(() => authService.isLoggedIn()).thenReturn(true);
    when(() => authService.currentUserId).thenReturn('fake-user');
    when(
      () => peopleRepository.getFamilyIdsForUser(any()),
    ).thenAnswer((_) async => ['fake-family']);
    when(
      () => peopleRepository.getMyFamilyRole(),
    ).thenAnswer((_) async => ['member']);
    when(
      () => getReminderUsecase(any(), type: any(named: 'type')),
    ).thenAnswer((_) async => const Right([]));
    when(() => getPeopleUsecase()).thenAnswer(
      (_) async => Right(
        PeopleData(
          family: FamilyEntity(name: '', inviteCode: ''),
          people: const [],
        ),
      ),
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget pumpApp({
    bool onboardingCompleted = true,
    AuthStateNotifier? authStateNotifier,
    String? initialLocation,
  }) {
    final getHomeData = _MockGetHomeDataUsecase();
    final hasReminders = _MockHasRemindersUsecase();
    when(
      () => getHomeData(),
    ).thenAnswer((_) async => Left(NoDataException()));
    when(
      () => hasReminders(),
    ).thenAnswer((_) async => const Right(false));
    return MultiBlocProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        BlocProvider<HomeCubit>(
          create: (_) => HomeCubit(
            getHomeDataUsecase: getHomeData,
            hasRemindersUsecase: hasReminders,
          ),
        ),
        BlocProvider<RemindersCubit>(
          create: (_) => RemindersCubit(
            getReminderUsecase: getReminderUsecase,
            peopleRepository: peopleRepository,
            authService: authService,
            reminderRepository: _MockReminderRepository(),
            notificationService: notifications,
          ),
        ),
        BlocProvider<PeopleCubit>(
          create: (_) => PeopleCubit(
            getPeopleUsecase: getPeopleUsecase,
            createFamilyUsecase: _MockCreateFamilyUsecase(),
            joinFamilyUsecase: _MockJoinFamilyUsecase(),
            authService: authService,
          ),
        ),
      ],
      child: MyApp(
        onboardingCompleted: onboardingCompleted,
        authStateNotifier: authStateNotifier,
        notificationService: notifications,
        initialLocation: initialLocation,
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    final labelFinder = find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text(label),
    );
    expect(labelFinder, findsOneWidget, reason: 'tab "$label" missing');
    await tester.tap(labelFinder);
    await settle(tester);
  }

  group('critical path: onboarding -> home -> reminders -> people', () {
    testWidgets('onboarding gate shows before the home shell', (tester) async {
      final notifier = AuthStateNotifier();
      addTearDown(notifier.dispose);

      await tester.pumpWidget(
        pumpApp(onboardingCompleted: false, authStateNotifier: notifier),
      );
      await settle(tester);

      expect(find.byType(OnboardingView), findsOneWidget);
      expect(find.byType(HomeView), findsNothing);
    });

    testWidgets('onboarding flow completes through all three pages', (
      tester,
    ) async {
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingView(onComplete: () => completed = true),
        ),
      );
      await tester.pump();

      // Page 1 -> 2 -> 3, then Get Started completes.
      await tester.tap(find.text('Next Step'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Next Step'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Get Started'), findsOneWidget);

      await tester.tap(find.text('Get Started'));
      await tester.pump();

      expect(completed, isTrue);
    });

    testWidgets('home -> reminders -> people -> home journey', (tester) async {
      final notifier = AuthStateNotifier();
      addTearDown(notifier.dispose);
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(pumpApp(authStateNotifier: notifier));
      await settle(tester);

      expect(find.byType(HomeView), findsOneWidget);

      await tapTab(tester, 'Reminders');
      expect(find.byType(RemindersView), findsOneWidget);

      await tapTab(tester, 'People');
      expect(find.byType(PeopleView), findsOneWidget);

      await tapTab(tester, 'Home');
      expect(find.byType(HomeView), findsOneWidget);

      stopwatch.stop();
      expect(
        stopwatch.elapsed,
        lessThan(startupBudget),
        reason: 'critical-path journey exceeded $startupBudget',
      );
    });

    testWidgets('cold start lands on home within the startup budget', (
      tester,
    ) async {
      final notifier = AuthStateNotifier();
      addTearDown(notifier.dispose);
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(pumpApp(authStateNotifier: notifier));
      await settle(tester);

      stopwatch.stop();
      expect(find.byType(HomeView), findsOneWidget);
      expect(
        stopwatch.elapsed,
        lessThan(startupBudget),
        reason: 'cold start exceeded $startupBudget',
      );
    });
  });
}
