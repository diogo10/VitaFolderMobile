import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_folder_mobile/main.dart';

void main() {
  group('MainView', () {
    testWidgets('displays Home tab by default', (tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.text('Home Content'), findsOneWidget);
      expect(find.text('Search Content'), findsNothing);
      expect(find.text('Favorites Content'), findsNothing);
      expect(find.text('Profile Content'), findsNothing);
    });

    testWidgets('displays bottom navigation bar with 4 items',
        (tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('switches tabs when tapping navigation items',
        (tester) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('Search'));
      await tester.pump();
      expect(find.text('Search Content'), findsOneWidget);

      await tester.tap(find.text('Favorites'));
      await tester.pump();
      expect(find.text('Favorites Content'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pump();
      expect(find.text('Profile Content'), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pump();
      expect(find.text('Home Content'), findsOneWidget);
    });
  });

  group('MyApp', () {
    testWidgets('has correct app title', (tester) async {
      await tester.pumpWidget(const MyApp());

      final title = tester.widget<MaterialApp>(find.byType(MaterialApp)).title;
      expect(title, 'VitaFolder');
    });

    testWidgets('renders MainView as home', (tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.byType(MainView), findsOneWidget);
    });
  });
}
