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

    group('isValidSupportUri', () {
      test('rejects null', () {
        expect(isValidSupportUri(null), isFalse);
      });

      test('rejects non-https and empty host', () {
        expect(
          isValidSupportUri(Uri.parse('http://housemira.com/support')),
          isFalse,
        );
        expect(isValidSupportUri(Uri.parse('https://')), isFalse);
        expect(isValidSupportUri(Uri.tryParse('not-a-url')), isFalse);
      });

      test('accepts the support URL', () {
        expect(isValidSupportUri(Uri.parse(AppRoutes.supportUrl)), isTrue);
      });
    });

    group('isInSupport', () {
      test('allows the base URL and subpaths', () {
        expect(isInSupport(Uri.parse('https://housemira.com/support')), isTrue);
        expect(
          isInSupport(Uri.parse('https://housemira.com/support/')),
          isTrue,
        );
        expect(
          isInSupport(Uri.parse('https://housemira.com/support/article')),
          isTrue,
        );
      });

      test('denies other hosts, subdomains, and prefix tricks', () {
        expect(isInSupport(Uri.parse('https://evil.com/support')), isFalse);
        expect(
          isInSupport(Uri.parse('https://sub.housemira.com/support')),
          isFalse,
        );
        expect(
          isInSupport(Uri.parse('https://housemira.com/support-evil')),
          isFalse,
        );
        expect(
          isInSupport(Uri.parse('https://housemira.com/other')),
          isFalse,
        );
        expect(isInSupport(Uri.parse('https://housemira.com/')), isFalse);
      });
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

    testWidgets('retry keeps the error visible for an invalid URL', (
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

      await tester.tap(find.text(l.supportRetry));
      await tester.pump();

      // Invalid URLs have no controller to reload, so the error UI stays
      // instead of flipping to a blank WebView.
      expect(find.text(l.supportLoadError), findsOneWidget);
      expect(find.text(l.supportRetry), findsOneWidget);
    });
  });
}
