import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira_account/presentation/views/support_screen.dart';
import 'package:house_mira_core/generated/app_localizations.dart';
import 'package:house_mira_core/router/app_routes.dart';

void main() {
  group('SupportScreen', () {
    test('defaults to the support website URL', () {
      expect(const SupportScreen().url, AppRoutes.supportUrl);
    });

    test('exposes the support route location', () {
      expect(AppRoutes.support, '/support');
    });

    testWidgets('shows a localized error with retry for an invalid URL', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SupportScreen(url: 'not-a-url'),
        ),
      );
      await tester.pump();

      final l = AppLocalizations.of(
        tester.element(find.byType(SupportScreen)),
      )!;
      expect(find.text(l.supportLoadError), findsOneWidget);
      expect(find.text(l.supportRetry), findsOneWidget);
    });
  });
}
