import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira_account/presentation/views/in_app_web_view_screen.dart';
import 'package:house_mira_core/generated/app_localizations.dart';
import 'package:house_mira_core/observability/app_logger.dart';
import 'package:house_mira_core/router/app_routes.dart';

void main() {
  group('InAppWebViewScreen', () {
    test('stores the url and title', () {
      const screen = InAppWebViewScreen(
        url: 'https://housemira.com/privacy',
        title: 'Privacy Policy',
      );
      expect(screen.url, 'https://housemira.com/privacy');
      expect(screen.title, 'Privacy Policy');
    });

    test('exposes the support route location', () {
      expect(AppRoutes.support, '/support');
    });

    test('exposes the privacy route location', () {
      expect(AppRoutes.privacy, '/privacy');
    });

    group('isValidWebViewUri', () {
      test('rejects null', () {
        expect(isValidWebViewUri(null), isFalse);
      });

      test('rejects non-https and empty host', () {
        expect(
          isValidWebViewUri(Uri.parse('http://housemira.com/support')),
          isFalse,
        );
        expect(isValidWebViewUri(Uri.parse('https://')), isFalse);
        expect(isValidWebViewUri(Uri.tryParse('not-a-url')), isFalse);
      });

      test('accepts the support URL', () {
        expect(isValidWebViewUri(Uri.parse(AppRoutes.supportUrl)), isTrue);
      });

      test('accepts the privacy URL', () {
        expect(
          isValidWebViewUri(Uri.parse(AppRoutes.privacyPolicyUrl)),
          isTrue,
        );
      });
    });

    group('staysInWebView', () {
      test('keeps every web link in the app, any host or path', () {
        expect(
          staysInWebView(Uri.parse('https://housemira.com/support')),
          isTrue,
        );
        expect(
          staysInWebView(Uri.parse('https://housemira.com/support/article')),
          isTrue,
        );
        expect(
          staysInWebView(Uri.parse('https://evil.com/support')),
          isTrue,
        );
        expect(staysInWebView(Uri.parse('http://example.com/')), isTrue);
      });

      test('sends non-web schemes externally', () {
        expect(staysInWebView(Uri.parse('mailto:a@b.c')), isFalse);
        expect(staysInWebView(Uri.parse('tel:+123456789')), isFalse);
      });
    });

    testWidgets('shows a localized error with retry for an invalid URL', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: InAppWebViewScreen(url: 'not-a-url', title: 'Support'),
        ),
      );
      await tester.pump();

      final l = AppLocalizations.of(
        tester.element(find.byType(InAppWebViewScreen)),
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
          home: InAppWebViewScreen(url: 'not-a-url', title: 'Support'),
        ),
      );
      await tester.pump();

      final l = AppLocalizations.of(
        tester.element(find.byType(InAppWebViewScreen)),
      )!;
      expect(find.text(l.supportLoadError), findsOneWidget);

      await tester.tap(find.text(l.supportRetry));
      await tester.pump();

      // Invalid URLs have no controller to reload, so the error UI stays
      // instead of flipping to a blank WebView.
      expect(find.text(l.supportLoadError), findsOneWidget);
      expect(find.text(l.supportRetry), findsOneWidget);
    });

    testWidgets('shows a snackbar when opening an external link fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: InAppWebViewScreen(
            url: 'not-a-url',
            title: 'Support',
            logger: AppLogger(sink: (_) {}),
            launchExternal: (_) async => false,
          ),
        ),
      );
      await tester.pump();

      final state = tester.state<InAppWebViewScreenState>(
        find.byType(InAppWebViewScreen),
      );
      await state.openExternal(Uri.parse('https://evil.com/'));
      await tester.pump();

      final l = AppLocalizations.of(
        tester.element(find.byType(InAppWebViewScreen)),
      )!;
      expect(find.text(l.supportExternalLinkError), findsOneWidget);
    });
  });
}
