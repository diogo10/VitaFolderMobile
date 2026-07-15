import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_folder_mobile/features/home/domain/entities/home_entity.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/home_view_success.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

void main() {
  final tEntity = HomeEntity(
    greeting: 'Good morning!',
    date: 'Monday, July 13',
    message: 'You have 3 tasks remaining today.',
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
    testWidgets('renders greeting from entity', (tester) async {
      await tester.pumpWidget(pumpApp(tEntity));

      expect(find.text('Good morning!'), findsOneWidget);
    });

    testWidgets('renders Today heading', (tester) async {
      await tester.pumpWidget(pumpApp(tEntity));

      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('renders stat cards with expected values', (tester) async {
      await tester.pumpWidget(pumpApp(tEntity));

      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('renders task card with message', (tester) async {
      await tester.pumpWidget(pumpApp(tEntity));

      expect(
        find.text('You have 3 tasks remaining today.'),
        findsOneWidget,
      );
    });

    testWidgets('renders FamilyHeaderWidget', (tester) async {
      await tester.pumpWidget(pumpApp(tEntity));

      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('shows different greeting when entity changes',
        (tester) async {
      final otherEntity = HomeEntity(
        greeting: 'Good evening!',
        date: 'Monday, July 13',
        message: 'You have 1 task remaining.',
      );

      await tester.pumpWidget(pumpApp(otherEntity));

      expect(find.text('Good evening!'), findsOneWidget);
      expect(find.text('Good morning!'), findsNothing);
    });
  });
}
