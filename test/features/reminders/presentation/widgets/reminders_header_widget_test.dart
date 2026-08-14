import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminders_header_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

void main() {
  group('RemindersHeaderWidget', () {
    Widget pumpApp() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: RemindersHeaderWidget(title: 'Reminders')),
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
  });
}
