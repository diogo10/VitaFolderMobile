import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/home/presentation/views/widgets/home_upcoming_reminders_widget.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/generated/app_localizations.dart';

ReminderEntity makeReminder(String id, String dueDate) => ReminderEntity(
  title: 'Reminder $id',
  body: '',
  id: id,
  type: ReminderType.custom,
  dueDate: dueDate,
  repeatRule: 'never',
  status: 'pending',
  createdBy: 'Mom',
  createdAt: '',
);

Widget pumpApp(List<ReminderEntity> reminders) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: HomeUpcomingRemindersWidget(reminders: reminders)),
  );
}

void main() {
  group('HomeUpcomingRemindersWidget No-date group', () {
    testWidgets('shows dateless reminders under No date header on top', (
      tester,
    ) async {
      final now = DateTime.now();
      final day = now.day.toString().padLeft(2, '0');
      final month = now.month.toString().padLeft(2, '0');
      final today = '$day/$month/${now.year}';

      await tester.pumpWidget(
        pumpApp([makeReminder('1', today), makeReminder('2', '')]),
      );
      final l = AppLocalizations.of(
        tester.element(find.byType(HomeUpcomingRemindersWidget)),
      )!;

      // Header + tile No-date chip share the same label.
      expect(find.text(l.homeSuccessRemindersNoDate), findsNWidgets(2));
      expect(find.text('Reminder 2'), findsOneWidget);
      expect(find.text('Reminder 1'), findsOneWidget);

      final datelessOffset = tester.getTopLeft(find.text('Reminder 2'));
      final datedOffset = tester.getTopLeft(find.text('Reminder 1'));
      expect(datelessOffset.dy, lessThan(datedOffset.dy));
      expect(find.text(l.homeSuccessRemindersToday), findsOneWidget);
    });

    testWidgets('dateless tile shows No date chip', (tester) async {
      await tester.pumpWidget(pumpApp([makeReminder('1', '')]));
      final l = AppLocalizations.of(
        tester.element(find.byType(HomeUpcomingRemindersWidget)),
      )!;

      expect(find.text(l.homeSuccessRemindersNoDate), findsWidgets);
      expect(find.text('Reminder 1'), findsOneWidget);
    });
  });
}
