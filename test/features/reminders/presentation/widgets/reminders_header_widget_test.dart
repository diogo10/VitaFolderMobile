import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_view_mode.dart';
import 'package:house_mira/features/reminders/presentation/widgets/reminders_header_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';

void main() {
  group('RemindersHeaderWidget', () {
    Widget pumpApp({
      RemindersViewMode? viewMode,
      VoidCallback? onCalendarPressed,
      VoidCallback? onFilterPressed,
    }) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RemindersHeaderWidget(
            title: 'Reminders',
            viewMode: viewMode,
            onCalendarPressed: onCalendarPressed,
            onFilterPressed: onFilterPressed,
          ),
        ),
      );
    }

    testWidgets('renders filter toggle button', (tester) async {
      await tester.pumpWidget(pumpApp());
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
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
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('fires onFilterPressed when filter button tapped', (
      tester,
    ) async {
      var pressed = false;
      await tester.pumpWidget(pumpApp(onFilterPressed: () => pressed = true));
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('shows notification dot when hasActiveFilters is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RemindersHeaderWidget(
              title: 'Reminders',
              hasActiveFilters: true,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      // The active-filter dot is the only Positioned widget in the header.
      expect(find.byType(Positioned), findsOneWidget);
    });

    testWidgets('hides notification dot when hasActiveFilters is false', (
      tester,
    ) async {
      await tester.pumpWidget(pumpApp());
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.byType(Positioned), findsNothing);
    });
  });
}
