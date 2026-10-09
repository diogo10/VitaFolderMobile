import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/local_storage/local_storage_datasource.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/people/presentation/cubit/people_cubit.dart';
import 'package:house_mira/features/people/presentation/cubit/people_state.dart';
import 'package:house_mira/features/people/presentation/views/people_view.dart';
import 'package:house_mira/features/people/presentation/widgets/people_empty_widget.dart';
import 'package:house_mira/features/people/presentation/widgets/people_loaded_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPeopleCubit extends MockCubit<PeopleState> implements PeopleCubit {}

class _MockAuthService extends Mock implements AuthService {}

void main() {
  late _MockPeopleCubit cubit;

  setUpAll(() {
    GetIt.instance.registerSingleton<LocalStorageDatasource>(
      LocalStorageDatasource(),
      instanceName: 'localStorageDatasource',
    );
  });

  setUp(() {
    cubit = _MockPeopleCubit();
    when(() => cubit.getPeople()).thenAnswer((_) async {});
    when(() => cubit.getPeople(isRefresh: true)).thenAnswer((_) async {});
    SharedPreferences.setMockInitialValues({});
  });

  Widget pumpApp(PeopleState state) {
    when(() => cubit.state).thenReturn(state);
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<PeopleCubit>.value(
          value: cubit,
          child: const PeopleView(),
        ),
      ),
    );
  }

  group('PeopleView pull-to-refresh', () {
    testWidgets('shows RefreshIndicator when state is empty', (tester) async {
      await tester.pumpWidget(pumpApp(PeopleEmpty()));

      expect(find.byType(PeopleEmptyWidget), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows RefreshIndicator when state is loaded', (tester) async {
      await tester.pumpWidget(
        pumpApp(
          PeopleLoaded(
            people: [const PersonEntity(id: '1', name: 'John', role: 'parent')],
            inviteCode: 'ABC123',
            familyName: 'The Smiths',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PeopleLoadedWidget), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets(
      'pull to refresh in empty state triggers getPeople with isRefresh',
      (tester) async {
        await tester.pumpWidget(pumpApp(PeopleEmpty()));
        await tester.pump();

        await tester.fling(
          find.byType(SingleChildScrollView),
          const Offset(0, 300),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));

        verify(() => cubit.getPeople(isRefresh: true)).called(1);
      },
    );

    testWidgets(
      'pull to refresh in loaded state triggers getPeople with isRefresh',
      (tester) async {
        await tester.pumpWidget(
          pumpApp(
            PeopleLoaded(
              people: [
                const PersonEntity(id: '1', name: 'John', role: 'parent'),
              ],
              inviteCode: 'ABC123',
              familyName: 'The Smiths',
            ),
          ),
        );
        await tester.pump();

        await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));

        verify(() => cubit.getPeople(isRefresh: true)).called(1);
      },
    );
  });

  group('PeopleView join flow', () {
    late _MockAuthService authService;

    setUp(() {
      authService = _MockAuthService();
      when(() => authService.isLoggedIn()).thenReturn(true);
      when(
        () => cubit.joinFamily(familyCode: any(named: 'familyCode')),
      ).thenAnswer((_) async {});
    });

    Widget pumpJoin({required VoidCallback onJoined}) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RepositoryProvider<AuthService>.value(
            value: authService,
            child: BlocProvider<PeopleCubit>.value(
              value: cubit,
              child: PeopleView(onJoined: onJoined),
            ),
          ),
        ),
      );
    }

    Future<void> enterCodeAndJoin(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField), 'ABC123');
      await tester.tap(find.text('Join Family'));
      await tester.pump();
    }

    testWidgets('shows success and calls onJoined after a successful join', (
      tester,
    ) async {
      final controller = StreamController<PeopleState>();
      addTearDown(controller.close);
      whenListen(
        cubit,
        controller.stream,
        initialState: PeopleEmpty(),
      );
      var joined = 0;
      await tester.pumpWidget(pumpJoin(onJoined: () => joined++));
      await tester.pump();

      await enterCodeAndJoin(tester);
      controller.add(PeopleLoading());
      await tester.pump();
      controller.add(
        PeopleLoaded(
          people: [const PersonEntity(id: '1', name: 'John', role: 'parent')],
          inviteCode: 'ABC123',
          familyName: 'The Smiths',
        ),
      );
      await tester.pump();

      expect(find.text("You've joined the family!"), findsOneWidget);
      expect(joined, 1);
    });

    testWidgets('shows invalid-code message and skips onJoined on failure', (
      tester,
    ) async {
      final controller = StreamController<PeopleState>();
      addTearDown(controller.close);
      whenListen(
        cubit,
        controller.stream,
        initialState: PeopleEmpty(),
      );
      var joined = 0;
      await tester.pumpWidget(pumpJoin(onJoined: () => joined++));
      await tester.pump();

      await enterCodeAndJoin(tester);
      controller.add(PeopleLoading());
      await tester.pump();
      controller.add(PeopleInvalidFamilyCode());
      await tester.pump();

      expect(
        find.text('Invalid family code. Please try again.'),
        findsOneWidget,
      );
      expect(joined, 0);
    });
  });
}
