import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_reminders_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

Widget _pumpApp() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: HomeEmptyRemindersWidget()),
  );
}

void main() {
  group('HomeEmptyRemindersWidget', () {
    testWidgets('renders Upcoming Reminders heading', (tester) async {
      await tester.pumpWidget(_pumpApp());

      expect(find.text('Upcoming Reminders'), findsOneWidget);
    });

    testWidgets('renders notification icon', (tester) async {
      await tester.pumpWidget(_pumpApp());

      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
    });

    testWidgets('renders No reminders yet message', (tester) async {
      await tester.pumpWidget(_pumpApp());

      expect(find.text('No reminders yet'), findsOneWidget);
    });

    testWidgets('renders description text', (tester) async {
      await tester.pumpWidget(_pumpApp());

      expect(
        find.text(
          'Create your first reminder to keep the family on track.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders Create Reminder button', (tester) async {
      await tester.pumpWidget(_pumpApp());

      expect(
        find.widgetWithText(ElevatedButton, 'Create Reminder'),
        findsOneWidget,
      );
    });
  });
}
