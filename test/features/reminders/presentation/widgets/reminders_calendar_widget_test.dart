import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminders_calendar_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

void main() {
  group('RemindersCalendarWidget', () {
    Widget pumpApp(List<ReminderEntity> reminders) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: RemindersCalendarWidget(reminders: reminders)),
      );
    }

    String fmt(DateTime d) {
      final day = d.day.toString().padLeft(2, '0');
      final month = d.month.toString().padLeft(2, '0');
      return '$day/$month/${d.year}';
    }

    ReminderEntity makeReminder(String id, String dueDate) => ReminderEntity(
      title: 'Reminder $id',
      body: '',
      id: id,
      type: ReminderType.appointment,
      dueDate: dueDate,
      repeatRule: 'never',
      status: 'pending',
      createdBy: '',
      createdAt: '',
    );

    testWidgets('shows current month in header', (tester) async {
      await tester.pumpWidget(pumpApp([]));
      final expected = DateFormat('MMMM yyyy').format(DateTime.now());
      expect(find.text(expected), findsOneWidget);
    });

    testWidgets('tapping a day with reminders lists them below', (
      tester,
    ) async {
      final now = DateTime.now();
      await tester.pumpWidget(pumpApp([makeReminder('1', fmt(now))]));

      await tester.tap(find.text('${now.day}'));
      await tester.pumpAndSettle();

      expect(find.text('Reminder 1'), findsOneWidget);
    });

    testWidgets('shows empty day message when no reminders on the day', (
      tester,
    ) async {
      final now = DateTime.now();
      await tester.pumpWidget(pumpApp([]));

      await tester.tap(find.text('${now.day}'));
      await tester.pumpAndSettle();

      final l = AppLocalizations.of(
        tester.element(find.byType(RemindersCalendarWidget)),
      )!;
      expect(find.text(l.remindersCalendarEmptyDay), findsOneWidget);
    });

    testWidgets('navigates to next and previous month', (tester) async {
      await tester.pumpWidget(pumpApp([]));
      final now = DateTime.now();
      final nextMonth = DateFormat(
        'MMMM yyyy',
      ).format(DateTime(now.year, now.month + 1));
      final currentMonth = DateFormat('MMMM yyyy').format(now);

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pump();
      expect(find.text(nextMonth), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pump();
      expect(find.text(currentMonth), findsOneWidget);
    });
  });
}
