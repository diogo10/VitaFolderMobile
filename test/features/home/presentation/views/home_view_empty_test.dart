import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/home_view_empty.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_header_widget.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_footer_widget.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_invite_card_widget.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_reminders_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

Widget _pumpApp() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: HomeViewEmpty(),
  );
}

void main() {
  group('HomeViewEmpty', () {
    testWidgets('renders HomeEmptyHeaderWidget', (tester) async {
      await tester.pumpWidget(_pumpApp());

      expect(find.byType(HomeEmptyHeaderWidget), findsOneWidget);
    });

    testWidgets('renders three action cards with correct labels',
        (tester) async {
      await tester.pumpWidget(_pumpApp());

      expect(find.text('Add people to your Circle'), findsOneWidget);
      expect(find.text('Set up a Reminder'), findsOneWidget);
      expect(find.text('Complete your Account'), findsOneWidget);
    });

    testWidgets('renders action card buttons', (tester) async {
      await tester.pumpWidget(_pumpApp());

      expect(find.widgetWithText(ElevatedButton, 'Add'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Set up'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Go'), findsOneWidget);
    });

    testWidgets('renders HomeEmptyInviteCardWidget', (tester) async {
      await tester.pumpWidget(_pumpApp());

      expect(find.byType(HomeEmptyInviteCardWidget), findsOneWidget);
    });

    testWidgets('renders HomeEmptyFooterWidget', (tester) async {
      await tester.pumpWidget(_pumpApp());

      expect(find.byType(HomeEmptyFooterWidget), findsOneWidget);
    });

    testWidgets('renders HomeEmptyRemindersWidget', (tester) async {
      await tester.pumpWidget(_pumpApp());

      expect(find.byType(HomeEmptyRemindersWidget), findsOneWidget);
    });
  });
}
