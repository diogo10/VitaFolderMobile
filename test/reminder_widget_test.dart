import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminder_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

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

    Widget buildTestWidget() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ReminderWidget(reminder: reminder),
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
  });
}