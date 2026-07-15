import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_footer_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

Widget _pumpApp() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: HomeEmptyFooterWidget()),
  );
}

void main() {
  group('HomeEmptyFooterWidget', () {
    testWidgets('renders The Circle heading', (tester) async {
      await tester.pumpWidget(_pumpApp());

      expect(find.text('The Circle'), findsOneWidget);
    });

    testWidgets('renders No members yet message', (tester) async {
      await tester.pumpWidget(_pumpApp());

      expect(find.text('No members yet'), findsOneWidget);
    });

    testWidgets('renders description text', (tester) async {
      await tester.pumpWidget(_pumpApp());

      expect(
        find.text(
          'Add family members to start collaborating and tracking together.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders group icon', (tester) async {
      await tester.pumpWidget(_pumpApp());

      expect(find.byIcon(Icons.group_rounded), findsOneWidget);
    });

    testWidgets('renders Add Member button', (tester) async {
      await tester.pumpWidget(_pumpApp());

      expect(find.widgetWithText(ElevatedButton, 'Add Member'), findsOneWidget);
    });
  });
}
