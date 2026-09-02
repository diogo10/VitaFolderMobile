import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/home/presentation/views/widgets/home_empty_invite_card_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';

void main() {
  group('HomeEmptyInviteCardWidget', () {
    Widget buildApp({required VoidCallback onSharePressed}) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeEmptyInviteCardWidget(onSharePressed: onSharePressed),
        ),
      );
    }

    testWidgets('renders Invite a Parent heading', (tester) async {
      await tester.pumpWidget(buildApp(onSharePressed: () {}));
      final l = AppLocalizations.of(
        tester.element(find.byType(HomeEmptyInviteCardWidget)),
      )!;

      expect(find.text(l.homeEmptyInviteInviteParentTitle), findsOneWidget);
    });

    testWidgets('renders collaboration description', (tester) async {
      await tester.pumpWidget(buildApp(onSharePressed: () {}));
      final l = AppLocalizations.of(
        tester.element(find.byType(HomeEmptyInviteCardWidget)),
      )!;

      expect(find.text(l.homeEmptyInviteInviteParentSubtitle), findsOneWidget);
    });

    testWidgets('renders Share button', (tester) async {
      await tester.pumpWidget(buildApp(onSharePressed: () {}));
      final l = AppLocalizations.of(
        tester.element(find.byType(HomeEmptyInviteCardWidget)),
      )!;

      expect(
        find.widgetWithText(ElevatedButton, l.homeEmptyInviteShareButton),
        findsOneWidget,
      );
    });

    testWidgets('fires onSharePressed when Share is tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(buildApp(onSharePressed: () => pressed = true));
      final l = AppLocalizations.of(
        tester.element(find.byType(HomeEmptyInviteCardWidget)),
      )!;

      await tester.tap(
        find.widgetWithText(ElevatedButton, l.homeEmptyInviteShareButton),
      );
      expect(pressed, isTrue);
    });
  });
}
