import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_folder_mobile/features/home/domain/entities/home_entity.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/home_view_success.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_header_widget.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_footer_widget.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_reminders_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

void main() {
  final tEntity = HomeEntity(peopleInCircle: []);

  Widget pumpApp(HomeEntity entity) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: HomeViewSuccess(data: entity)),
    );
  }

  group('HomeViewSuccess', () {
    testWidgets('renders HomeEmptyHeaderWidget', (tester) async {
      await tester.pumpWidget(pumpApp(tEntity));

      expect(find.byType(HomeEmptyHeaderWidget), findsOneWidget);
    });

    testWidgets('renders three action cards with correct labels', (
      tester,
    ) async {
      await tester.pumpWidget(pumpApp(tEntity));
      final l = AppLocalizations.of(
        tester.element(find.byType(HomeViewSuccess)),
      )!;

      expect(find.text(l.homeEmptyAddPeopleTitle), findsOneWidget);
      expect(find.text(l.homeEmptyReminderTitle), findsOneWidget);
      expect(find.text(l.homeEmptyAccountTitle), findsOneWidget);
    });

    testWidgets('renders action card buttons', (tester) async {
      await tester.pumpWidget(pumpApp(tEntity));
      final l = AppLocalizations.of(
        tester.element(find.byType(HomeViewSuccess)),
      )!;

      expect(
        find.widgetWithText(ElevatedButton, l.homeEmptyAddPeopleButton),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ElevatedButton, l.homeEmptyReminderButton),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ElevatedButton, l.homeEmptyAccountButton),
        findsOneWidget,
      );
    });

    testWidgets('renders HomeEmptyFooterWidget', (tester) async {
      await tester.pumpWidget(pumpApp(tEntity));

      expect(find.byType(HomeEmptyFooterWidget), findsOneWidget);
    });

    testWidgets('renders HomeEmptyRemindersWidget', (tester) async {
      await tester.pumpWidget(pumpApp(tEntity));

      expect(find.byType(HomeEmptyRemindersWidget), findsOneWidget);
    });

    testWidgets('renders reminders section with localized heading', (
      tester,
    ) async {
      await tester.pumpWidget(pumpApp(tEntity));
      final l = AppLocalizations.of(
        tester.element(find.byType(HomeViewSuccess)),
      )!;

      expect(find.text(l.homeEmptyRemindersSectionTitle), findsOneWidget);
    });
  });
}
