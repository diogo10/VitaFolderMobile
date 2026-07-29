import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_folder_mobile/features/home/domain/entities/home_entity.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/home_view_success.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_header_widget.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_footer_widget.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_reminders_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

void main() {
  final tEntity = HomeEntity(
    greeting: 'Good morning!',
    date: 'Monday, July 13',
    message: 'You have 3 tasks remaining today.',
    peopleInCircle: [],
  );

  Widget pumpApp(HomeEntity entity) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: HomeViewSuccess(data: entity),
      ),
    );
  }

  group('HomeViewSuccess', () {
    testWidgets('renders HomeEmptyHeaderWidget', (tester) async {
      await tester.pumpWidget(pumpApp(tEntity));

      expect(find.byType(HomeEmptyHeaderWidget), findsOneWidget);
    });

    testWidgets('renders three action cards with correct labels',
        (tester) async {
      await tester.pumpWidget(pumpApp(tEntity));

      expect(find.text('Add people to your Circle'), findsOneWidget);
      expect(find.text('Set up a Reminder'), findsOneWidget);
      expect(find.text('Complete your Account'), findsOneWidget);
    });

    testWidgets('renders action card buttons', (tester) async {
      await tester.pumpWidget(pumpApp(tEntity));

      expect(find.widgetWithText(ElevatedButton, 'Add'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Set up'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Go'), findsOneWidget);
    });

    testWidgets('renders HomeEmptyFooterWidget', (tester) async {
      await tester.pumpWidget(pumpApp(tEntity));

      expect(find.byType(HomeEmptyFooterWidget), findsOneWidget);
    });

    testWidgets('renders HomeEmptyRemindersWidget', (tester) async {
      await tester.pumpWidget(pumpApp(tEntity));

      expect(find.byType(HomeEmptyRemindersWidget), findsOneWidget);
    });

    testWidgets('renders reminders section with localized heading',
        (tester) async {
      await tester.pumpWidget(pumpApp(tEntity));

      expect(find.text('Upcoming Reminders'), findsOneWidget);
    });
  });
}
