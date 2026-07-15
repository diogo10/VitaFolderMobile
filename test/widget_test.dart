import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vita_folder_mobile/core/injections/service_locator.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_cubit.dart';
import 'package:vita_folder_mobile/features/home/domain/entities/home_entity.dart';
import 'package:vita_folder_mobile/features/home/domain/repository/home_repository.dart';
import 'package:vita_folder_mobile/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_cubit.dart';
import 'package:vita_folder_mobile/features/onboarding/data/datasource/onboarding_local_datasource.dart';
import 'package:vita_folder_mobile/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:vita_folder_mobile/features/people/domain/usecase/get_people_usecase.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/people_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/data/datasource/reminder_remote_datasource.dart'
    as reminders;
import 'package:vita_folder_mobile/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/main.dart';

class _MockHomeRepository implements HomeRepository {
  @override
  Future<Either<Exception, HomeEntity>> getHomeData() async {
    return Right(
      HomeEntity(
        greeting: 'Good morning!',
        date: 'Monday, July 13',
        message: 'You have 3 tasks remaining today.',
      ),
    );
  }
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
          getReminderUsecase: GetIt.instance<GetReminderUsecase>(
            instanceName: 'getReminderUsecase',
          ),
        ),
      ),
      BlocProvider<PeopleCubit>(
        create: (_) => PeopleCubit(
          getPeopleUsecase: GetIt.instance<GetPeopleUsecase>(
            instanceName: 'getPeopleUsecase',
          ),
        ),
      ),
      BlocProvider<AccountCubit>(create: (_) => AccountCubit()),
    ],
    child: const MyApp(),
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
          getReminderUsecase: GetIt.instance<GetReminderUsecase>(
            instanceName: 'getReminderUsecase',
          ),
        ),
      ),
      BlocProvider<PeopleCubit>(
        create: (_) => PeopleCubit(
          getPeopleUsecase: GetIt.instance<GetPeopleUsecase>(
            instanceName: 'getPeopleUsecase',
          ),
        ),
      ),
      BlocProvider<AccountCubit>(create: (_) => AccountCubit()),
    ],
    child: MyApp(showOnboarding: true),
  );
}

class _MockDioAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    throw DioException(
      type: DioExceptionType.connectionError,
      requestOptions: options,
      message: 'Mock adapter',
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    final serviceLocator = ServiceLocator();
    await serviceLocator.init();

    await slInstance.unregister<HomeCubit>(instanceName: 'homeCubit');
    await slInstance.unregister<GetHomeDataUsecase>(instanceName: 'getHomeDataUsecase');
    await slInstance.unregister<HomeRepository>(instanceName: 'homeRepositoryImpl');
    slInstance.registerSingleton<HomeRepository>(
      _MockHomeRepository(),
      instanceName: 'homeRepositoryImpl',
    );
    slInstance.registerSingleton<GetHomeDataUsecase>(
      GetHomeDataUsecase(
        repository: slInstance<HomeRepository>(
          instanceName: 'homeRepositoryImpl',
        ),
      ),
      instanceName: 'getHomeDataUsecase',
    );

    reminders.http.httpClientAdapter = _MockDioAdapter();
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  group('MainView', () {
    testWidgets('displays Home tab by default', (tester) async {
      await tester.pumpWidget(_pumpApp());
      await tester.pump();
      await tester.pump();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Good morning!'), findsOneWidget);
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
      addTearDown(() => tester.pump(const Duration(seconds: 11)));
      await tester.pumpWidget(_pumpApp());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Reminders'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 15));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('People'));
      await tester.pump();
      await tester.pump();
      expect(find.text('The Circle'), findsOneWidget);
      expect(find.text('Family Invite Code'), findsOneWidget);
      expect(find.text('1 Pending Invite'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Members'), 300);
      expect(find.text('Members'), findsOneWidget);
      expect(find.text('Sarah Smith'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Role Permissions'), 300);
      expect(find.text('Add Family Member'), findsOneWidget);
      expect(find.text('Role Permissions'), findsOneWidget);

      await tester.tap(find.text('Account'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Account'), findsAtLeastNWidgets(2));

      await tester.tap(find.text('Home'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Today'), findsOneWidget);
    });
  });

  group('MyApp', () {
    testWidgets('has correct app title', (tester) async {
      await tester.pumpWidget(_pumpApp());

      final title = tester.widget<MaterialApp>(find.byType(MaterialApp)).title;
      await tester.pump(const Duration(seconds: 11));
      expect(title, 'VitaFolder');
    });

    testWidgets('renders MainView as home when onboarding completed', (
      tester,
    ) async {
      await tester.pumpWidget(_pumpApp());
      await tester.pump();

      await tester.pump(const Duration(seconds: 11));
      expect(find.byType(MainView), findsOneWidget);
    });
  });

  group('Onboarding', () {
    testWidgets('shows onboarding when not completed', (tester) async {
      await tester.pumpWidget(_pumpAppWithOnboarding());
      await tester.pump();

      expect(find.byType(OnboardingView), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('displays 3 pages with navigation dots', (tester) async {
      await tester.pumpWidget(_pumpAppWithOnboarding());
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      final pageView = find.byType(PageView);
      await tester.drag(pageView, const Offset(-500, 0));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      await tester.drag(pageView, const Offset(-500, 0));
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
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
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('skip navigates to MainView', (tester) async {
      await tester.pumpWidget(_pumpAppWithOnboarding());
      await tester.pump();

      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MainView), findsOneWidget);
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
