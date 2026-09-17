import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/auth/auth_state_notifier.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/core/router/app_router.dart';
import 'package:house_mira/core/router/splash_view.dart';
import 'package:house_mira/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:house_mira/features/home/domain/usecase/has_reminders_usecase.dart';
import 'package:house_mira/features/home/presentation/cubit/home_cubit.dart';
import 'package:house_mira/features/home/presentation/views/home_view.dart';
import 'package:house_mira/features/login/presentation/cubit/sign_up_cubit.dart';
import 'package:house_mira/features/login/presentation/views/sign_up_screen.dart';
import 'package:house_mira/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSession extends Mock implements Session {}

class _MockGetHomeDataUsecase extends Mock implements GetHomeDataUsecase {}

class _MockHasRemindersUsecase extends Mock implements HasRemindersUsecase {}

class _MockAuthService extends Mock implements AuthService {}

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

  Future<void> pumpRouter(
    WidgetTester tester,
    GoRouter router, {
    AuthService? authService,
  }) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<HomeCubit>(
            create: (_) => HomeCubit(
              getHomeDataUsecase: getHomeData,
              hasRemindersUsecase: hasReminders,
            ),
          ),
          BlocProvider<SignUpCubit>(
            create: (_) => SignUpCubit(authService ?? _MockAuthService()),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();
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

  group('AppRouter session recovery and auth listener', () {
    testWidgets(
      'holds splash until the initial session is recovered (no FOUNC)',
      (tester) async {
        final notifier = AuthStateNotifier(
          authStateStream: authEvents.stream,
        );
        addTearDown(notifier.dispose);
        final router = createRouter(
          onboardingCompleted: true,
          authStateNotifier: notifier,
        );

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
      final router = createRouter(
        onboardingCompleted: true,
        authStateNotifier: notifier,
      );

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
      final router = createRouter(
        onboardingCompleted: false,
        authStateNotifier: notifier,
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
      final router = createRouter(
        onboardingCompleted: true,
        authStateNotifier: notifier,
      );

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
      final router = createRouter(
        onboardingCompleted: true,
        authStateNotifier: notifier,
      );

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
      final router = createRouter(
        onboardingCompleted: true,
        authStateNotifier: notifier,
      );

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
