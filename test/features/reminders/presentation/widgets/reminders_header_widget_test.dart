import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_view_mode.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminders_header_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

void main() {
  group('RemindersHeaderWidget', () {
    Widget pumpApp({
      RemindersViewMode? viewMode,
      VoidCallback? onCalendarPressed,
    }) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RemindersHeaderWidget(
            title: 'Reminders',
            viewMode: viewMode,
            onCalendarPressed: onCalendarPressed,
          ),
        ),
      );
    }

    testWidgets('renders a chip for every ReminderType', (tester) async {
      await tester.pumpWidget(pumpApp());
      final l = AppLocalizations.of(
        tester.element(find.byType(RemindersHeaderWidget)),
      )!;

      for (final type in ReminderType.values) {
        final label = switch (type) {
          ReminderType.renewal => l.createReminderTypeRenewal,
          ReminderType.appointment => l.createReminderTypeAppointment,
          ReminderType.vaccine => l.createReminderTypeVaccine,
          ReminderType.reimbursement => l.createReminderTypeReimbursement,
          ReminderType.birthday => l.createReminderTypeBirthday,
          ReminderType.chores => l.createReminderTypeChores,
          ReminderType.custom => l.createReminderTypeCustom,
        };
        await tester.scrollUntilVisible(
          find.widgetWithText(ChoiceChip, label),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.widgetWithText(ChoiceChip, label), findsOneWidget);
      }
    });

    testWidgets('renders All chip first', (tester) async {
      await tester.pumpWidget(pumpApp());
      final l = AppLocalizations.of(
        tester.element(find.byType(RemindersHeaderWidget)),
      )!;

      final allChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, l.remindersHeaderAll),
      );
      expect(allChip.selected, isTrue);
    });

    testWidgets('renders calendar toggle button', (tester) async {
      await tester.pumpWidget(pumpApp());
      expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
    });

    testWidgets('swaps to list icon in calendar view', (tester) async {
      await tester.pumpWidget(pumpApp(viewMode: RemindersViewMode.calendar));
      expect(find.byIcon(Icons.view_list_rounded), findsOneWidget);
    });

    testWidgets('fires onCalendarPressed when tapped', (tester) async {
      var pressed = false;
      await tester.pumpWidget(pumpApp(onCalendarPressed: () => pressed = true));
      await tester.tap(find.byIcon(Icons.calendar_month_rounded));
      expect(pressed, isTrue);
    });
  });
}
