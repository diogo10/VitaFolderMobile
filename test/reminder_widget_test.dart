import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/domain/repository/reminder_repository.dart';
import 'package:vita_folder_mobile/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminder_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

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
      dueDate: '2026-08-10',
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

    testWidgets('renders title, body and due date', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text(reminder.title), findsOneWidget);
      expect(find.text(reminder.body), findsOneWidget);
      expect(find.text(reminder.dueDate), findsOneWidget);
    });

    testWidgets('renders title with bold style', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final titleWidget = tester.widget<Text>(find.text(reminder.title));
      expect(titleWidget.style?.fontWeight, FontWeight.bold);
      expect(titleWidget.style?.fontSize, 18);
    });

    testWidgets('renders inside a Card widget', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets(
      'double tap opens remove dialog and removes reminder on confirm',
      (tester) async {
        final repository = _FakeReminderRepository();
        final peopleRepository = _FakePeopleRepository();
        when(
          () => repository.removeReminder(1),
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

        await tester.tap(find.text(reminder.title));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.text(reminder.title));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.text('Are you sure you want to remove "${reminder.title}"?'),
          findsOneWidget,
        );

        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();

        verify(() => repository.removeReminder(1)).called(1);

        await cubit.close();
      },
    );
  });
}
