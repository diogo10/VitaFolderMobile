import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_lead_time.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';
import 'package:house_mira/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:house_mira/features/reminders/presentation/widgets/reminder_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _FakeReminderRepository extends Mock implements ReminderRepository {}

class _FakePeopleRepository extends Mock implements PeopleRepository {}

class _FakeAuthService extends Mock implements AuthService {}

class _FakeGetReminderUsecase extends Mock implements GetReminderUsecase {}

class _NoopNotificationService implements IReminderNotificationService {
  @override
  Future<void> init() async {}

  @override
  Stream<String?> get onNotificationTap => const Stream.empty();

  @override
  Future<String?> getLaunchPayload() async => null;

  @override
  Future<bool> hasSystemPermission() async => false;

  @override
  Future<bool> requestSystemPermission() async => false;

  @override
  Future<bool> canScheduleExactAlarms() async => true;

  @override
  Future<void> requestExactAlarmPermission() async {}

  @override
  Future<ReminderNotificationPrefs> getReminderNotification(
    String reminderId,
  ) async => ReminderNotificationPrefs.disabled;

  @override
  Future<bool> setReminderNotification({
    required String reminderId,
    required bool enabled,
    required ReminderLeadTime leadTime,
    required DateTime? dueDate,
    required String title,
    required String body,
    required String repeatRule,
  }) async => true;

  @override
  Future<void> cancelReminderNotification(String reminderId) async {}

  @override
  Future<bool> showTestNotification({
    required String title,
    required String body,
  }) async => true;

  @override
  Future<void> rescheduleAll(List<ReminderEntity> reminders) async {}
}

void main() {
  group('ReminderWidget', () {
    const reminder = ReminderEntity(
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
                  notificationService: _NoopNotificationService(),
                ),
            child: const ReminderWidget(reminder: reminder),
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

    testWidgets('does not render type chip', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Type chip was removed; icon already communicates the type
      expect(find.text('Appointment'), findsNothing);
    });

    testWidgets('renders assignee name', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('user-1'), findsOneWidget);
    });

    testWidgets('tap on card reveals edit and remove options in bottom sheet', (
      tester,
    ) async {
      final peopleRepository = _FakePeopleRepository();
      when(
        peopleRepository.getMyFamilyRole,
      ).thenAnswer((_) async => <String>[]);

      final cubit = RemindersCubit(
        getReminderUsecase: _FakeGetReminderUsecase(),
        peopleRepository: peopleRepository,
        authService: _FakeAuthService(),
        reminderRepository: _FakeReminderRepository(),
        notificationService: _NoopNotificationService(),
      );

      await tester.pumpWidget(buildTestWidget(cubit: cubit));

      // Tap on the card itself (title), not the 3-dots menu
      await tester.tap(find.text(reminder.title));
      await tester.pumpAndSettle();

      // Same bottom sheet as the 3-dots menu should appear
      expect(find.text('Edit Reminder'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('tap on menu reveals edit and remove options in bottom sheet', (
      tester,
    ) async {
      final repository = _FakeReminderRepository();
      final peopleRepository = _FakePeopleRepository();
      when(
        () => repository.removeReminder(reminder.id),
      ).thenAnswer((_) async => const Right(true));
      when(
        peopleRepository.getMyFamilyRole,
      ).thenAnswer((_) async => <String>[]);

      final cubit = RemindersCubit(
        getReminderUsecase: _FakeGetReminderUsecase(),
        peopleRepository: peopleRepository,
        authService: _FakeAuthService(),
        reminderRepository: repository,
        notificationService: _NoopNotificationService(),
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
