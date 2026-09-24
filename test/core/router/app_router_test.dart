import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/auth/auth_state_notifier.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/core/router/app_router.dart';
import 'package:house_mira/core/router/splash_view.dart';
import 'package:house_mira/features/account/presentation/cubit/account_cubit.dart';
import 'package:house_mira/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:house_mira/features/home/domain/usecase/has_reminders_usecase.dart';
import 'package:house_mira/features/home/presentation/cubit/home_cubit.dart';
import 'package:house_mira/features/home/presentation/views/home_view.dart';
import 'package:house_mira/features/login/presentation/cubit/sign_up_cubit.dart';
import 'package:house_mira/features/login/presentation/views/sign_up_screen.dart';
import 'package:house_mira/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:house_mira/features/people/domain/entities/family_entity.dart';
import 'package:house_mira/features/people/domain/entities/people_data.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/people/domain/usecase/create_family_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/get_people_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/join_family_usecase.dart';
import 'package:house_mira/features/people/presentation/cubit/people_cubit.dart';
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';
import 'package:house_mira/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSession extends Mock implements Session {}

class _MockGetHomeDataUsecase extends Mock implements GetHomeDataUsecase {}

class _MockHasRemindersUsecase extends Mock implements HasRemindersUsecase {}

class _MockAuthService extends Mock implements AuthService {}

class _MockGetPeopleUsecase extends Mock implements GetPeopleUsecase {}

class _MockCreateFamilyUsecase extends Mock implements CreateFamilyUsecase {}

class _MockJoinFamilyUsecase extends Mock implements JoinFamilyUsecase {}

class _MockPeopleRepository extends Mock implements PeopleRepository {}

class _MockGetReminderUsecase extends Mock implements GetReminderUsecase {}

class _MockReminderRepository extends Mock implements ReminderRepository {}

class _FakeNotificationService extends Fake
    implements IReminderNotificationService {}

void main() {
  late StreamController<AuthState> authEvents;
  late _MockGetHomeDataUsecase getHomeData;
  late _MockHasRemindersUsecase hasReminders;

  setUp(() {
    authEvents = StreamController<AuthState>.broadcast();
    getHomeData = _MockGetHomeDataUsecase();
    hasReminders = _MockHasRemindersUsecase();
    when(
      () => getHomeData(),
    ).thenAnswer((_) async => Left(NoDataException()));
    when(
      () => hasReminders(),
    ).thenAnswer((_) async => const Right(false));
  });

  tearDown(() async {
    await authEvents.close();
  });

  Future<void> pumpRouter(WidgetTester tester, GoRouter router) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pump();
  }

  /// Builds a router with route-scoped test cubits. Only the visited
  /// route's factory is resolved: go_router builds just the active branch,
  /// so untouched tabs and one-shot screens stay unbuilt until navigated
  /// to (pinned by 'route-scoped cubit laziness' below).
  GoRouter buildRouter({
    required AuthStateNotifier notifier,
    bool onboardingCompleted = true,
    AuthService? authService,
  }) {
    final resolvedAuth = authService ?? _MockAuthService();
    final getPeopleUsecase = _MockGetPeopleUsecase();
    when(() => getPeopleUsecase()).thenAnswer(
      (_) async => Right(
        PeopleData(
          family: FamilyEntity(name: '', inviteCode: ''),
          people: const [],
        ),
      ),
    );
    final peopleRepository = _MockPeopleRepository();
    when(
      () => peopleRepository.getFamilyIdsForUser(any()),
    ).thenAnswer((_) async => ['fake-family']);
    when(
      () => peopleRepository.getMyFamilyRole(),
    ).thenAnswer((_) async => ['member']);
    final getReminderUsecase = _MockGetReminderUsecase();
    when(
      () => getReminderUsecase(any(), type: any(named: 'type')),
    ).thenAnswer((_) async => const Right([]));
    final homeCubit = HomeCubit(
      getHomeDataUsecase: getHomeData,
      hasRemindersUsecase: hasReminders,
    );
    final peopleCubit = PeopleCubit(
      getPeopleUsecase: getPeopleUsecase,
      createFamilyUsecase: _MockCreateFamilyUsecase(),
      joinFamilyUsecase: _MockJoinFamilyUsecase(),
      authService: resolvedAuth,
    );
    final remindersCubit = RemindersCubit(
      getReminderUsecase: getReminderUsecase,
      peopleRepository: peopleRepository,
      authService: resolvedAuth,
      reminderRepository: _MockReminderRepository(),
      notificationService: _FakeNotificationService(),
    );
    final accountCubit = AccountCubit(
      authService: resolvedAuth,
      peopleRepository: peopleRepository,
    );
    final signUpCubit = SignUpCubit(resolvedAuth);
    // NOTE: signUpCubit is owned by the router's BlocProvider(create:) and
    // closed on disposal — never close it manually (double-close hangs).
    // The tab cubits use BlocProvider.value (no ownership) so they are
    // closed here.
    addTearDown(() async {
      await homeCubit.close();
      await peopleCubit.close();
      await remindersCubit.close();
      await accountCubit.close();
    });
    return createRouter(
      onboardingCompleted: onboardingCompleted,
      authStateNotifier: notifier,
      homeCubitFactory: () => homeCubit,
      peopleCubitFactory: () => peopleCubit,
      remindersCubitFactory: () => remindersCubit,
      accountCubitFactory: () => accountCubit,
      signUpCubitFactory: () => signUpCubit,
    );
  }

  /// Delivers an auth event and lets the router redirect settle.
  ///
  /// Uses explicit pumps instead of [WidgetTester.pumpAndSettle] because the
  /// splash screen shows an infinitely animating progress indicator. The
  /// longer durations let the outgoing page transition finish so the
  /// previous route is fully removed from the tree.
  Future<void> emitAuth(WidgetTester tester, AuthState state) async {
    authEvents.add(state);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  group('route-scoped cubit laziness', () {
    testWidgets('cold start resolves only the active tab cubit', (
      tester,
    ) async {
      final notifier = AuthStateNotifier();
      addTearDown(notifier.dispose);
      final resolved = <String>[];
      Never unexpected(String name) =>
          throw StateError('$name factory must stay lazy on cold start');
      final homeCubit = HomeCubit(
        getHomeDataUsecase: getHomeData,
        hasRemindersUsecase: hasReminders,
      );
      addTearDown(homeCubit.close);
      final router = createRouter(
        onboardingCompleted: true,
        authStateNotifier: notifier,
        initialLocation: '/home',
        homeCubitFactory: () {
          resolved.add('home');
          return homeCubit;
        },
        peopleCubitFactory: () => unexpected('people'),
        remindersCubitFactory: () => unexpected('reminders'),
        accountCubitFactory: () => unexpected('account'),
        createReminderCubitFactory: () => unexpected('createReminder'),
        signUpCubitFactory: () => unexpected('signUp'),
        invitePeopleCubitFactory: () => unexpected('invitePeople'),
        familySettingsCubitFactory: () => unexpected('familySettings'),
        notificationSettingsCubitFactory: () =>
            unexpected('notificationSettings'),
        manageProfileCubitFactory: () => unexpected('manageProfile'),
      );

      await pumpRouter(tester, router);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.byType(HomeView), findsOneWidget);
      // Startup win over the old eager MultiBlocProvider graph: a cold
      // start to /home constructs exactly one cubit instead of the whole
      // tab + one-shot graph. Must stay within the host startup budget
      // (tool/performance_budgets.json: test_host_startup_s).
      expect(resolved, ['home']);
    });
  });

  group('AppRouter session recovery and auth listener', () {
    testWidgets(
      'holds splash until the initial session is recovered (no FOUNC)',
      (tester) async {
        final notifier = AuthStateNotifier(
          authStateStream: authEvents.stream,
        );
        addTearDown(notifier.dispose);
        final router = buildRouter(notifier: notifier);

        await pumpRouter(tester, router);

        // Auth state undetermined: splash gate, no authenticated or
        // unauthenticated content may flash.
        expect(find.byType(SplashView), findsOneWidget);
        expect(find.byType(HomeView), findsNothing);
        expect(router.state.uri.path, '/splash');

        // Session recovery completes with no stored session.
        await emitAuth(
          tester,
          const AuthState(AuthChangeEvent.initialSession, null),
        );

        expect(find.byType(SplashView), findsNothing);
        expect(find.byType(HomeView), findsOneWidget);
        expect(router.state.uri.path, '/home');
      },
    );

    testWidgets('recovers an existing session upon restart', (tester) async {
      final notifier = AuthStateNotifier(
        authStateStream: authEvents.stream,
      );
      addTearDown(notifier.dispose);
      final router = buildRouter(notifier: notifier);

      await pumpRouter(tester, router);
      expect(router.state.uri.path, '/splash');

      final session = _MockSession();
      await emitAuth(
        tester,
        AuthState(AuthChangeEvent.initialSession, session),
      );

      expect(notifier.isInitialized, isTrue);
      expect(notifier.isAuthenticated, isTrue);
      expect(router.state.uri.path, '/home');
      expect(find.byType(HomeView), findsOneWidget);
    });

    testWidgets('routes to onboarding after recovery when not completed', (
      tester,
    ) async {
      final notifier = AuthStateNotifier(
        authStateStream: authEvents.stream,
      );
      addTearDown(notifier.dispose);
      final router = buildRouter(
        notifier: notifier,
        onboardingCompleted: false,
      );

      await pumpRouter(tester, router);
      expect(find.byType(SplashView), findsOneWidget);

      await emitAuth(
        tester,
        const AuthState(AuthChangeEvent.initialSession, null),
      );

      expect(router.state.uri.path, '/onboarding');
      expect(find.byType(OnboardingView), findsOneWidget);
    });

    testWidgets('redirects signed-in users away from sign-up', (tester) async {
      final notifier = AuthStateNotifier(
        authStateStream: authEvents.stream,
      );
      addTearDown(notifier.dispose);
      final router = buildRouter(notifier: notifier);

      await pumpRouter(tester, router);

      final session = _MockSession();
      await emitAuth(
        tester,
        AuthState(AuthChangeEvent.initialSession, session),
      );
      expect(router.state.uri.path, '/home');

      router.go('/sign-up');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(router.state.uri.path, '/home');
      expect(find.byType(HomeView), findsOneWidget);
      expect(find.byType(SignUpView), findsNothing);
    });

    testWidgets('allows guests on sign-up while signed out', (tester) async {
      final notifier = AuthStateNotifier(
        authStateStream: authEvents.stream,
      );
      addTearDown(notifier.dispose);
      final router = buildRouter(notifier: notifier);

      await pumpRouter(tester, router);
      await emitAuth(
        tester,
        const AuthState(AuthChangeEvent.initialSession, null),
      );

      router.go('/sign-up');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(router.state.uri.path, '/sign-up');
      expect(find.byType(SignUpView), findsOneWidget);
    });

    testWidgets('sign-out keeps guests on home and re-enables sign-up', (
      tester,
    ) async {
      final notifier = AuthStateNotifier(
        authStateStream: authEvents.stream,
      );
      addTearDown(notifier.dispose);
      final router = buildRouter(notifier: notifier);

      await pumpRouter(tester, router);

      // Sign in: recovered session lands on home.
      final session = _MockSession();
      await emitAuth(tester, AuthState(AuthChangeEvent.signedIn, session));
      expect(router.state.uri.path, '/home');

      // Sign out while on home: guest browsing is allowed, no forced
      // navigation, but the notifier reflects the signed-out state.
      await emitAuth(
        tester,
        const AuthState(AuthChangeEvent.signedOut, null),
      );
      expect(notifier.isAuthenticated, isFalse);
      expect(router.state.uri.path, '/home');

      // Sign-up is reachable again while signed out.
      router.go('/sign-up');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(router.state.uri.path, '/sign-up');
      expect(find.byType(SignUpView), findsOneWidget);
    });
  });
}
