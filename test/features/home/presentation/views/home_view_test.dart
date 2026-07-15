import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_folder_mobile/features/home/domain/entities/home_entity.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_cubit.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_state.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/home_view.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class _MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

void main() {
  late HomeCubit cubit;

  setUp(() {
    cubit = _MockHomeCubit();
    when(() => cubit.getHomeData()).thenAnswer((_) async {});
  });

  Widget pumpApp(HomeState state) {
    when(() => cubit.state).thenReturn(state);
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<HomeCubit>.value(
          value: cubit,
          child: const HomeView(),
        ),
      ),
    );
  }

  group('HomeView', () {
    testWidgets('shows progress indicator when loading',
        (tester) async {
      await tester.pumpWidget(pumpApp(HomeLoading()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when error occurs', (tester) async {
      await tester.pumpWidget(pumpApp(HomeError()));

      expect(find.text('Something went wrong.'), findsOneWidget);
    });

    testWidgets('shows HomeViewEmpty when state is empty', (tester) async {
      await tester.pumpWidget(pumpApp(HomeEmpty()));

      expect(find.text('Welcome to FamilyAdmin'), findsOneWidget);
    });

    testWidgets('shows HomeViewSuccess when state is loaded', (tester) async {
      final entity = HomeEntity(
        greeting: 'Good morning!',
        date: 'Monday, July 13',
        message: 'You have 3 tasks remaining today.',
      );

      await tester.pumpWidget(pumpApp(HomeLoaded(data: entity)));

      expect(find.text('Today'), findsOneWidget);
    });
  });
}
