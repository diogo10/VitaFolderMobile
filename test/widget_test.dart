import 'package:fpdart/fpdart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/core/injections/service_locator.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_cubit.dart';
import 'package:vita_folder_mobile/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_cubit.dart';
import 'package:vita_folder_mobile/features/onboarding/data/datasource/onboarding_local_datasource.dart';
import 'package:vita_folder_mobile/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/family_entity.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/person_entity.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';
import 'package:vita_folder_mobile/features/people/domain/usecase/create_family_usecase.dart';
import 'package:vita_folder_mobile/features/people/domain/usecase/get_people_usecase.dart';
import 'package:vita_folder_mobile/features/people/domain/usecase/join_family_usecase.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/people_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/data/models/reminder_model.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/domain/repository/reminder_repository.dart';
import 'package:vita_folder_mobile/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/main.dart';

class _FakeAuthService extends AuthService {
  @override
  bool isLoggedIn() => true;

  @override
  String get currentUserId => 'fake-user';
}

class _FakePeopleRepository implements PeopleRepository {
  @override
  Future<Either<Exception, List<PersonEntity>>> getPeople() async => Right([]);

  @override
  Future<Either<Exception, bool>> createFamily({required String name, required String inviteCode}) async => Right(true);

  @override
  Future<Either<Exception, FamilyEntity>> getMyFamily() async => Right(
        FamilyEntity(name: 'Fam', inviteCode: 'ABC'),
      );

  @override
  Future<Either<Exception, bool>> joinFamily({required String inviteCode}) async => Right(true);

  @override
  Future<FamilyEntity?> getFamilyBy(String id) async => FamilyEntity(name: 'Fam', inviteCode: 'ABC');

  @override
  Future<List<String>> getFamilyIdsForUser(String userId) async => ['fake-family'];

  @override
  Future<List<PersonEntity>> getProfilesWithRoleForFamily(String familyId) async => [];

  @override
  Future<List<String>> getMyFamilyRole() async => ['member'];
}

class _FakeReminderRepository implements ReminderRepository {
  @override
  Future<Either<Failure, List<ReminderEntity>>> getReminders(String familyId) async => Right([]);

  @override
  Future<Either<Failure, List<ReminderEntity>>> getRemindersByTypeAndFamily({
    required ReminderType type,
    required String familyId,
  }) async => Right([]);

  @override
  Future<Either<Failure, bool>> createReminder(ReminderModel reminder) async => Right(true);

  @override
  Future<Either<Failure, bool>> removeReminder(int id) async => Right(true);
}

Widget _pumpApp() {
  return MultiBlocProvider(
    providers: [
      BlocProvider<HomeCubit>(
        create: (_) => HomeCubit(
          getHomeDataUsecase: GetIt.instance<GetHomeDataUsecase>(
            instanceName: 'getHomeDataUsecase',
          ),
        ),
      ),
      BlocProvider<RemindersCubit>(
        create: (_) => RemindersCubit(
          getReminderUsecase: GetReminderUsecase(
            repository: _FakeReminderRepository(),
          ),
          peopleRepository: _FakePeopleRepository(),
          authService: _FakeAuthService(),
        ),
      ),
      BlocProvider<PeopleCubit>(
        create: (_) => PeopleCubit(
          getPeopleUsecase: GetIt.instance<GetPeopleUsecase>(
            instanceName: 'getPeopleUsecase',
          ),
          createFamilyUsecase: GetIt.instance<CreateFamilyUsecase>(
            instanceName: 'createFamilyUsecase',
          ),
          joinFamilyUsecase: GetIt.instance<JoinFamilyUsecase>(
            instanceName: 'joinFamilyUsecase',
          ),
        ),
      ),
      BlocProvider<AccountCubit>(
        create: (_) => GetIt.instance<AccountCubit>(
          instanceName: 'accountCubit',
        ),
      ),
    ],
    child: const MyApp(onboardingCompleted: true),
  );
}

Widget _pumpAppWithOnboarding() {
  return MultiBlocProvider(
    providers: [
      BlocProvider<HomeCubit>(
        create: (_) => HomeCubit(
          getHomeDataUsecase: GetIt.instance<GetHomeDataUsecase>(
            instanceName: 'getHomeDataUsecase',
          ),
        ),
      ),
      BlocProvider<RemindersCubit>(
        create: (_) => RemindersCubit(
          getReminderUsecase: GetReminderUsecase(
            repository: _FakeReminderRepository(),
          ),
          peopleRepository: _FakePeopleRepository(),
          authService: _FakeAuthService(),
        ),
      ),
      BlocProvider<PeopleCubit>(
        create: (_) => PeopleCubit(
          getPeopleUsecase: GetIt.instance<GetPeopleUsecase>(
            instanceName: 'getPeopleUsecase',
          ),
          createFamilyUsecase: GetIt.instance<CreateFamilyUsecase>(
            instanceName: 'createFamilyUsecase',
          ),
          joinFamilyUsecase: GetIt.instance<JoinFamilyUsecase>(
            instanceName: 'joinFamilyUsecase',
          ),
        ),
      ),
      BlocProvider<AccountCubit>(
        create: (_) => GetIt.instance<AccountCubit>(
          instanceName: 'accountCubit',
        ),
      ),
    ],
    child: const MyApp(onboardingCompleted: false),
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    await Supabase.initialize(
      url: 'https://mock.supabase.co',
      publishableKey: 'mock-anon-key',
    );
    final serviceLocator = ServiceLocator();
    await serviceLocator.init();

    await slInstance.unregister<HomeCubit>(instanceName: 'homeCubit');
    await slInstance.unregister<GetHomeDataUsecase>(instanceName: 'getHomeDataUsecase');
    slInstance.registerSingleton<GetHomeDataUsecase>(
      GetHomeDataUsecase(
        authService: _FakeAuthService(),
        peopleRepository: _FakePeopleRepository(),
      ),
      instanceName: 'getHomeDataUsecase',
    );
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  group('MainShell', () {
    testWidgets('displays Home tab by default', (tester) async {
      await tester.pumpWidget(_pumpApp());
      await tester.pump();
      await tester.pump();

      expect(find.text('Welcome to FamilyAdmin'), findsOneWidget);
      expect(find.text('Upcoming Reminders'), findsOneWidget);
      expect(find.text('Search Content'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('displays bottom navigation bar with 4 items', (tester) async {
      await tester.pumpWidget(_pumpApp());
      await tester.pump();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Reminders'), findsOneWidget);
      expect(find.text('People'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('switches tabs when tapping navigation items', (tester) async {
      await tester.pumpWidget(_pumpApp());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Reminders'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 15));
      expect(find.text('No reminders yet'), findsOneWidget);

      await tester.tap(find.text('People'));
      await tester.pump();
      await tester.pump();
      expect(find.text('No family members yet'), findsOneWidget);
      expect(find.text('Add your first family member to get started.'), findsOneWidget);

      await tester.tap(find.text('Account'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Account'), findsAtLeastNWidgets(1));

      await tester.tap(find.text('Home'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Welcome to FamilyAdmin'), findsOneWidget);
    });
  });

  group('MyApp', () {
    testWidgets('has correct app title', (tester) async {
      await tester.pumpWidget(_pumpApp());

      final title = tester.widget<MaterialApp>(find.byType(MaterialApp)).title;
      await tester.pump(const Duration(seconds: 11));
      expect(title, 'VitaFolder');
    });

    testWidgets('renders shell when onboarding completed', (
      tester,
    ) async {
      await tester.pumpWidget(_pumpApp());
      await tester.pump();

      await tester.pump(const Duration(seconds: 11));
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });
  });

  group('Onboarding', () {
    testWidgets('shows onboarding when not completed', (tester) async {
      await tester.pumpWidget(_pumpAppWithOnboarding());
      await tester.pump();

      expect(find.byType(OnboardingView), findsOneWidget);
      expect(find.text('Bring your whole family together'), findsOneWidget);
    });

    testWidgets('displays 3 pages with navigation dots', (tester) async {
      await tester.pumpWidget(_pumpAppWithOnboarding());
      await tester.pump();

      expect(find.text('Bring your whole family together'), findsOneWidget);

      final pageView = find.byType(PageView);
      await tester.drag(pageView, const Offset(-500, 0));
      await tester.pump();
      expect(find.text('Stay on top of every task'), findsOneWidget);

      await tester.drag(pageView, const Offset(-500, 0));
      await tester.pump();
      expect(find.text('Celebrate every moment as a family'), findsOneWidget);
    });

    testWidgets('shows skip and next buttons', (tester) async {
      await tester.pumpWidget(_pumpAppWithOnboarding());
      await tester.pump();

      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Get Started'), findsNothing);
    });

    testWidgets('shows Get Started on last page', (tester) async {
      await tester.pumpWidget(_pumpAppWithOnboarding());
      await tester.pump();

      expect(find.text('Next'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Stay on top of every task'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.pump();

      expect(find.text('Celebrate every moment as a family'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('skip navigates to shell', (tester) async {
      await tester.pumpWidget(_pumpAppWithOnboarding());
      await tester.pump();

      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('marks onboarding as completed on skip', (tester) async {
      await tester.pumpWidget(_pumpAppWithOnboarding());
      await tester.pump();

      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final datasource = GetIt.instance<OnboardingLocalDatasource>(
        instanceName: 'onboardingLocalDatasource',
      );
      final completed = await datasource.isOnboardingCompleted();
      expect(completed, isTrue);
    });
  });
}
