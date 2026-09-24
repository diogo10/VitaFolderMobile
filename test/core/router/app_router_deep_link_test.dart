import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/auth/auth_state_notifier.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/core/functions/edget_functions.dart';
import 'package:house_mira/core/router/app_router.dart';
import 'package:house_mira/features/account/presentation/cubit/account_cubit.dart';
import 'package:house_mira/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:house_mira/features/home/domain/usecase/has_reminders_usecase.dart';
import 'package:house_mira/features/home/presentation/cubit/home_cubit.dart';
import 'package:house_mira/features/login/presentation/cubit/sign_up_cubit.dart';
import 'package:house_mira/features/people/domain/entities/family_entity.dart';
import 'package:house_mira/features/people/domain/entities/people_data.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/people/domain/usecase/create_family_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/get_people_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/join_family_usecase.dart';
import 'package:house_mira/features/people/presentation/cubit/invite_people_cubit.dart';
import 'package:house_mira/features/people/presentation/cubit/people_cubit.dart';
import 'package:house_mira/features/people/presentation/views/invite_people_screen.dart';
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';
import 'package:house_mira/features/reminders/domain/usecase/create_reminder_usecase.dart';
import 'package:house_mira/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:house_mira/features/reminders/domain/usecase/update_reminder_usecase.dart';
import 'package:house_mira/features/reminders/presentation/cubit/create_reminder_cubit.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:house_mira/features/reminders/presentation/screens/create_reminder_screen.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockGetPeopleUsecase extends Mock implements GetPeopleUsecase {}

class _MockCreateFamilyUsecase extends Mock implements CreateFamilyUsecase {}

class _MockJoinFamilyUsecase extends Mock implements JoinFamilyUsecase {}

class _MockEdgetFunctions extends Mock implements EdgetFunctions {}

class _MockGetReminderUsecase extends Mock implements GetReminderUsecase {}

class _MockReminderRepository extends Mock implements ReminderRepository {}

class _MockCreateReminderUsecase extends Mock
    implements CreateReminderUsecase {}

class _MockUpdateReminderUsecase extends Mock
    implements UpdateReminderUsecase {}

class _MockGetHomeDataUsecase extends Mock implements GetHomeDataUsecase {}

class _MockHasRemindersUsecase extends Mock implements HasRemindersUsecase {}

void main() {
  late _MockAuthService authService;
  late _MockGetPeopleUsecase getPeopleUsecase;

  PeopleData emptyFamily() => PeopleData(
    family: FamilyEntity(name: '', inviteCode: ''),
    people: const [],
  );

  setUp(() {
    authService = _MockAuthService();
    getPeopleUsecase = _MockGetPeopleUsecase();
    when(() => authService.isLoggedIn()).thenReturn(false);
    when(
      () => getPeopleUsecase(),
    ).thenAnswer((_) async => Right(emptyFamily()));
  });

  Widget pumpRouter(GoRouter router) {
    return Provider<AuthService>.value(
      value: authService,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  /// Builds a router with route-scoped test cubits. Only the visited
  /// route's factory is resolved: go_router builds just the active branch,
  /// so untouched tabs and one-shot screens stay unbuilt until navigated
  /// to (pinned by 'route-scoped cubit laziness' in app_router_test).
  GoRouter buildRouter({
    required AuthStateNotifier notifier,
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
    final getReminderUsecase = _MockGetReminderUsecase();
    when(
      () => getReminderUsecase(any(), type: any(named: 'type')),
    ).thenAnswer((_) async => const Right([]));
    final peopleRepository = _FakePeopleRepository();
    when(
      () => peopleRepository.getFamilyIdsForUser(any()),
    ).thenAnswer((_) async => ['fake-family']);
    when(
      () => peopleRepository.getMyFamilyRole(),
    ).thenAnswer((_) async => ['member']);
    final homeCubit = HomeCubit(
      getHomeDataUsecase: getHomeData,
      hasRemindersUsecase: hasReminders,
    );
    final peopleCubit = PeopleCubit(
      getPeopleUsecase: getPeopleUsecase,
      createFamilyUsecase: _MockCreateFamilyUsecase(),
      joinFamilyUsecase: _MockJoinFamilyUsecase(),
      authService: authService,
    );
    final remindersCubit = RemindersCubit(
      getReminderUsecase: getReminderUsecase,
      peopleRepository: peopleRepository,
      authService: authService,
      reminderRepository: _MockReminderRepository(),
      notificationService: _FakeNotificationService(),
    );
    final accountCubit = AccountCubit(
      authService: authService,
      peopleRepository: peopleRepository,
    );
    // Factory contract (see createRouter): tab factories are shared (single
    // instance, BlocProvider.value, closed here); one-shot factories are
    // fresh per call (BlocProvider(create:) owns and closes them — never
    // close manually, never return the same instance twice).
    CreateReminderCubit buildCreateCubit() => CreateReminderCubit(
      createReminderUsecase: _MockCreateReminderUsecase(),
      updateReminderUsecase: _MockUpdateReminderUsecase(),
      authService: authService,
      peopleRepository: _FakePeopleRepository(),
      notificationService: _FakeNotificationService(),
    );
    addTearDown(() async {
      await homeCubit.close();
      await peopleCubit.close();
      await remindersCubit.close();
      await accountCubit.close();
    });
    return createRouter(
      onboardingCompleted: true,
      authStateNotifier: notifier,
      initialLocation: initialLocation,
      homeCubitFactory: () => homeCubit,
      peopleCubitFactory: () => peopleCubit,
      remindersCubitFactory: () => remindersCubit,
      accountCubitFactory: () => accountCubit,
      signUpCubitFactory: () => SignUpCubit(authService),
      invitePeopleCubitFactory: () =>
          InvitePeopleCubit(edgetFunctions: _MockEdgetFunctions()),
      createReminderCubitFactory: buildCreateCubit,
    );
  }

  /// Lets route transitions settle without pumpAndSettle (the splash
  /// progress indicator animates indefinitely).
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  String joinFieldText(WidgetTester tester) {
    final fields = find.byType(TextField);
    expect(fields, findsOneWidget);
    return tester.widget<TextField>(fields).controller?.text ?? '';
  }

  group('invite deep links', () {
    testWidgets('path code lands on people with the code pre-filled', (
      tester,
    ) async {
      final notifier = AuthStateNotifier();
      addTearDown(notifier.dispose);
      final router = buildRouter(
        notifier: notifier,
        initialLocation: '/invite/ABC123',
      );

      await tester.pumpWidget(pumpRouter(router));
      await settle(tester);

      expect(router.state.uri.path, '/invite/ABC123');
      expect(joinFieldText(tester), 'ABC123');
    });

    testWidgets('query code is accepted as well', (tester) async {
      final notifier = AuthStateNotifier();
      addTearDown(notifier.dispose);
      final router = buildRouter(
        notifier: notifier,
        initialLocation: '/invite?code=XYZ789',
      );

      await tester.pumpWidget(pumpRouter(router));
      await settle(tester);

      expect(joinFieldText(tester), 'XYZ789');
    });

    testWidgets('invalid codes fall back to people with an empty field', (
      tester,
    ) async {
      final notifier = AuthStateNotifier();
      addTearDown(notifier.dispose);
      final router = buildRouter(
        notifier: notifier,
        initialLocation: '/invite/!!!',
      );

      await tester.pumpWidget(pumpRouter(router));
      await settle(tester);

      expect(router.state.uri.path, '/people');
      expect(joinFieldText(tester), '');
    });

    testWidgets('cold-start deep link survives session recovery', (
      tester,
    ) async {
      final authEvents = StreamController<AuthState>.broadcast();
      addTearDown(authEvents.close);
      final notifier = AuthStateNotifier(
        authStateStream: authEvents.stream,
      );
      addTearDown(notifier.dispose);
      final router = buildRouter(
        notifier: notifier,
        initialLocation: '/invite/ABC123',
      );

      await tester.pumpWidget(pumpRouter(router));
      await tester.pump();
      // Recovery in flight: splash holds, deep link preserved in next.
      expect(router.state.uri.path, '/splash');
      expect(
        router.state.uri.queryParameters['next'],
        '/invite/ABC123',
      );

      authEvents.add(const AuthState(AuthChangeEvent.initialSession, null));
      await settle(tester);

      expect(router.state.uri.path, '/invite/ABC123');
      expect(joinFieldText(tester), 'ABC123');
    });
  });

  group('typed reminder extras', () {
    testWidgets('unknown extras open a fresh form instead of crashing', (
      tester,
    ) async {
      final notifier = AuthStateNotifier();
      addTearDown(notifier.dispose);
      final router = buildRouter(notifier: notifier);

      await tester.pumpWidget(pumpRouter(router));
      await settle(tester);

      unawaited(router.push('/create-reminder', extra: Object()));
      await settle(tester);

      expect(find.byType(CreateReminderScreen), findsOneWidget);
    });

    testWidgets('reminder-type extras pre-select the type', (tester) async {
      final notifier = AuthStateNotifier();
      addTearDown(notifier.dispose);
      final router = buildRouter(notifier: notifier);

      await tester.pumpWidget(pumpRouter(router));
      await settle(tester);

      unawaited(
        router.push(
          '/create-reminder',
          extra: ReminderType.birthday,
        ),
      );
      await settle(tester);

      expect(find.byType(CreateReminderScreen), findsOneWidget);
      expect(router.state.uri.path, '/create-reminder');
    });

    testWidgets('reminder-type query param opens the form', (tester) async {
      final notifier = AuthStateNotifier();
      addTearDown(notifier.dispose);
      final router = buildRouter(notifier: notifier);

      await tester.pumpWidget(pumpRouter(router));
      await settle(tester);

      unawaited(router.push('/create-reminder?type=vaccine'));
      await settle(tester);

      expect(find.byType(CreateReminderScreen), findsOneWidget);
      expect(
        router.state.uri.queryParameters['type'],
        'vaccine',
      );
    });
  });

  group('invite-people extras', () {
    testWidgets('family name extra renders the family hero copy', (
      tester,
    ) async {
      when(() => authService.isLoggedIn()).thenReturn(true);
      final notifier = AuthStateNotifier();
      addTearDown(notifier.dispose);
      final router = buildRouter(notifier: notifier);

      await tester.pumpWidget(pumpRouter(router));
      await settle(tester);

      unawaited(router.push('/invite-people', extra: 'Fam'));
      await settle(tester);

      expect(find.byType(InvitePeopleScreen), findsOneWidget);
      expect(find.textContaining('Fam', findRichText: true), findsOneWidget);
    });
  });
}

class _FakePeopleRepository extends Mock implements PeopleRepository {}

// Never interacted with in these tests (no save/permission toggles);
// a Fake keeps construction lightweight.
class _FakeNotificationService extends Fake
    implements IReminderNotificationService {}
