import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/features/home/domain/entities/home_entity.dart';
import 'package:house_mira/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:house_mira/features/home/domain/usecase/has_reminders_usecase.dart';
import 'package:house_mira/features/home/presentation/cubit/home_cubit.dart';
import 'package:house_mira/features/home/presentation/views/home_view_success.dart';
import 'package:house_mira/features/home/presentation/views/widgets/home_circle_widget.dart';
import 'package:house_mira/features/home/presentation/views/widgets/home_success_header_widget.dart';
import 'package:house_mira/features/home/presentation/views/widgets/home_upcoming_reminders_widget.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _FakeGetHomeDataUsecase extends Mock implements GetHomeDataUsecase {}

class _FakeHasRemindersUsecase extends Mock implements HasRemindersUsecase {}

void main() {
  const tEntity = HomeEntity(
    peopleInCircle: [],
    familyName: 'Smith Family',
    myRole: 'admin',
    activeMembers: 4,
  );

  late HomeCubit cubit;
  late _FakeGetHomeDataUsecase getHomeDataUsecase;
  late _FakeHasRemindersUsecase hasRemindersUsecase;

  setUp(() {
    getHomeDataUsecase = _FakeGetHomeDataUsecase();
    hasRemindersUsecase = _FakeHasRemindersUsecase();
    cubit = HomeCubit(
      getHomeDataUsecase: getHomeDataUsecase,
      hasRemindersUsecase: hasRemindersUsecase,
    );
  });

  Widget pumpApp(HomeEntity entity) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: HomeViewSuccess(data: entity),
        ),
      ),
    );
  }

  group('HomeViewSuccess', () {
    testWidgets('renders HomeSuccessHeaderWidget', (tester) async {
      await tester.pumpWidget(pumpApp(tEntity));

      expect(find.byType(HomeSuccessHeaderWidget), findsOneWidget);
    });

    testWidgets('renders family name and active members summary', (
      tester,
    ) async {
      await tester.pumpWidget(pumpApp(tEntity));
      final l = AppLocalizations.of(
        tester.element(find.byType(HomeViewSuccess)),
      )!;

      expect(find.text('Smith Family'), findsOneWidget);
      expect(find.text(l.homeSuccessActiveMembers(4, 0)), findsOneWidget);
    });

    testWidgets('renders action cards with correct labels', (tester) async {
      await tester.pumpWidget(pumpApp(tEntity));
      final l = AppLocalizations.of(
        tester.element(find.byType(HomeViewSuccess)),
      )!;

      expect(find.text(l.homeSuccessAddTaskTitle), findsOneWidget);
      expect(find.text(l.homeSuccessManageActivityTitle), findsOneWidget);
    });

    testWidgets('renders action card buttons', (tester) async {
      await tester.pumpWidget(pumpApp(tEntity));
      final l = AppLocalizations.of(
        tester.element(find.byType(HomeViewSuccess)),
      )!;

      expect(
        find.widgetWithText(ElevatedButton, l.homeSuccessAddTaskButton),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ElevatedButton, l.homeSuccessManageActivityButton),
        findsOneWidget,
      );
    });

    testWidgets('renders HomeCircleWidget when people present', (tester) async {
      await tester.pumpWidget(
        pumpApp(
          const HomeEntity(
            peopleInCircle: [PersonEntity(name: 'Mom', role: 'parent')],
            familyName: 'Smith Family',
          ),
        ),
      );

      expect(find.byType(HomeCircleWidget), findsOneWidget);
    });

    testWidgets('renders HomeEmptyRemindersWidget when no reminders', (
      tester,
    ) async {
      await tester.pumpWidget(pumpApp(tEntity));

      expect(find.byType(HomeUpcomingRemindersWidget), findsNothing);
    });

    testWidgets('renders reminders tiles when reminders exist', (tester) async {
      final entity = HomeEntity(
        peopleInCircle: const [],
        familyName: 'Smith Family',
        reminders: [
          ReminderEntity(
            title: "Lily's Allergy Meds",
            body: 'Take medicine below stairs',
            id: '1',
            type: ReminderType.renewal,
            dueDate: _today(),
            repeatRule: 'daily',
            status: 'pending',
            createdBy: 'Mom',
            createdAt: '',
          ),
        ],
      );

      await tester.pumpWidget(pumpApp(entity));

      expect(find.byType(HomeUpcomingRemindersWidget), findsOneWidget);
      expect(find.text("Lily's Allergy Meds"), findsOneWidget);
    });

    testWidgets('renders reminders section with localized heading', (
      tester,
    ) async {
      await tester.pumpWidget(pumpApp(tEntity));
      final l = AppLocalizations.of(
        tester.element(find.byType(HomeViewSuccess)),
      )!;

      expect(find.text(l.homeEmptyRemindersSectionTitle), findsOneWidget);
    });

    testWidgets('shows RefreshIndicator and refreshes on pull', (tester) async {
      when(
        () => getHomeDataUsecase(),
      ).thenAnswer((_) async => const Right(tEntity));
      when(
        () => hasRemindersUsecase(),
      ).thenAnswer((_) async => const Right(false));

      await tester.pumpWidget(pumpApp(tEntity));
      expect(find.byType(RefreshIndicator), findsOneWidget);

      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      verify(() => getHomeDataUsecase()).called(1);
    });
  });
}

String _today() {
  final now = DateTime.now();
  final day = now.day.toString().padLeft(2, '0');
  final month = now.month.toString().padLeft(2, '0');
  return '$day/$month/${now.year}';
}
