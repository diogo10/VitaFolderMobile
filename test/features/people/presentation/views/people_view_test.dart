import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:house_mira/core/local_storage/local_storage_datasource.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/people/presentation/cubit/people_cubit.dart';
import 'package:house_mira/features/people/presentation/cubit/people_state.dart';
import 'package:house_mira/features/people/presentation/views/people_view.dart';
import 'package:house_mira/features/people/presentation/widgets/people_empty_widget.dart';
import 'package:house_mira/features/people/presentation/widgets/people_loaded_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';

class _MockPeopleCubit extends MockCubit<PeopleState> implements PeopleCubit {}

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
            people: [PersonEntity(id: '1', name: 'John', role: 'parent')],
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
              people: [PersonEntity(id: '1', name: 'John', role: 'parent')],
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
}
