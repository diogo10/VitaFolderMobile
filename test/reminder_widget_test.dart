import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';
import 'package:house_mira/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:house_mira/features/reminders/presentation/widgets/reminder_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';

class _FakeReminderRepository extends Mock implements ReminderRepository {}

class _FakePeopleRepository extends Mock implements PeopleRepository {}

class _FakeAuthService extends Mock implements AuthService {}

class _FakeGetReminderUsecase extends Mock implements GetReminderUsecase {}

void main() {
  group('ReminderWidget', () {
    final reminder = ReminderEntity(
      id: '1',
      title: 'Test Title',
      body: 'Test Body Content',
      type: ReminderType.appointment,
      dueDate: '22/08/2026 15:00',
      repeatRule: 'never',
      status: 'pending',
      createdBy: 'user-1',
      createdAt: '2026-08-01',
    );

    Widget buildTestWidget({RemindersCubit? cubit}) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<RemindersCubit>(
            create: (_) =>
                cubit ??
                RemindersCubit(
                  getReminderUsecase: _FakeGetReminderUsecase(),
                  peopleRepository: _FakePeopleRepository(),
                  authService: _FakeAuthService(),
                  reminderRepository: _FakeReminderRepository(),
                ),
            child: ReminderWidget(reminder: reminder),
          ),
        ),
      );
    }

    testWidgets('renders title, body and time', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text(reminder.title), findsOneWidget);
      expect(find.text(reminder.body), findsOneWidget);
      // Time is displayed in the description and trailing section
      expect(find.text('15:00'), findsWidgets);
    });

    testWidgets('renders title with bold style', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final titleWidget = tester.widget<Text>(find.text(reminder.title));
      expect(titleWidget.style?.fontWeight, FontWeight.w700);
      expect(titleWidget.style?.fontSize, 14);
    });

    testWidgets('renders inside a Card widget', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renders type chip', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Should render the appointment type chip
      expect(find.text('Appointment'), findsOneWidget);
    });

    testWidgets('renders assignee name', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('user-1'), findsOneWidget);
    });

    testWidgets('tap on menu reveals edit and remove options in bottom sheet', (
      tester,
    ) async {
      final repository = _FakeReminderRepository();
      final peopleRepository = _FakePeopleRepository();
      when(
        () => repository.removeReminder(reminder.id),
      ).thenAnswer((_) async => Right(true));
      when(
        () => peopleRepository.getMyFamilyRole(),
      ).thenAnswer((_) async => <String>[]);

      final cubit = RemindersCubit(
        getReminderUsecase: _FakeGetReminderUsecase(),
        peopleRepository: peopleRepository,
        authService: _FakeAuthService(),
        reminderRepository: repository,
      );

      await tester.pumpWidget(buildTestWidget(cubit: cubit));

      // Menu icon should be visible
      expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

      // Tap on menu icon
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      // Bottom sheet should appear with edit and remove options
      expect(find.text('Edit Reminder'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);

      // Tap remove
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // Confirm dialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text('Are you sure you want to remove "${reminder.title}"?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      verify(() => repository.removeReminder(reminder.id)).called(1);

      await cubit.close();
    });
  });
}
