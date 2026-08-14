import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_state.dart';
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
    home: HomeViewEmpty(state: const HomeEmpty()),
  );
}

void main() {
  group('HomeViewEmpty', () {
    testWidgets('renders HomeEmptyHeaderWidget', (tester) async {
      await tester.pumpWidget(_pumpApp());

      expect(find.byType(HomeEmptyHeaderWidget), findsOneWidget);
    });

    testWidgets('renders three action cards with correct labels', (
      tester,
    ) async {
      await tester.pumpWidget(_pumpApp());
      final l = AppLocalizations.of(
        tester.element(find.byType(HomeViewEmpty)),
      )!;

      expect(find.text(l.homeEmptyAddPeopleTitle), findsOneWidget);
      expect(find.text(l.homeEmptyReminderTitle), findsOneWidget);
      expect(find.text(l.homeEmptyAccountTitle), findsOneWidget);
    });

    testWidgets('renders action card buttons', (tester) async {
      await tester.pumpWidget(_pumpApp());
      final l = AppLocalizations.of(
        tester.element(find.byType(HomeViewEmpty)),
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
