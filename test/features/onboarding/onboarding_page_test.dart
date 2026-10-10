import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira_core/observability/app_logger.dart';
import 'package:house_mira_core/router/app_routes.dart';
import 'package:house_mira_onboarding/data/datasource/onboarding_local_datasource.dart';
import 'package:house_mira_onboarding/presentation/pages/onboarding_page.dart';
import 'package:house_mira_onboarding/presentation/views/onboarding_view.dart';
import 'package:house_mira_core/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockDatasource extends Mock implements OnboardingLocalDatasource {}

class _MockAppLogger extends Mock implements AppLogger {}

GoRouter testRouter(OnboardingLocalDatasource datasource, {AppLogger? logger}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            OnboardingPage(datasource: datasource, logger: logger),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const Scaffold(body: Text('home')),
      ),
    ],
  );
}

Future<void> pumpPage(
  WidgetTester tester,
  OnboardingLocalDatasource datasource, {
  AppLogger? logger,
}) async {
  final router = testRouter(datasource, logger: logger);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
  await tester.pump();
}

Future<void> reachLastPage(WidgetTester tester) async {
  final l = AppLocalizations.of(tester.element(find.byType(OnboardingView)))!;
  await tester.tap(find.text(l.onboardingSkip));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

AppLocalizations labelsOf(WidgetTester tester) {
  return AppLocalizations.of(tester.element(find.byType(OnboardingView)))!;
}

void main() {
  group('OnboardingPage completion', () {
    testWidgets('failure shows localized SnackBar instead of throwing', (
      tester,
    ) async {
      final datasource = _MockDatasource();
      when(datasource.completeOnboarding).thenThrow(Exception('disk full'));
      await pumpPage(tester, datasource);
      await reachLastPage(tester);
      final l = labelsOf(tester);

      await tester.tap(find.text(l.onboardingGetStarted));
      await tester.pump();

      expect(find.text(l.onboardingCompleteFailed), findsOneWidget);
      verify(datasource.completeOnboarding).called(1);
    });

    testWidgets('success navigates home without error snackbar', (
      tester,
    ) async {
      final datasource = _MockDatasource();
      when(datasource.completeOnboarding).thenAnswer((_) async {});
      await pumpPage(tester, datasource);
      await reachLastPage(tester);
      final l = labelsOf(tester);

      await tester.tap(find.text(l.onboardingGetStarted));
      await tester.pump();
      await tester.pump();

      expect(find.text('home'), findsOneWidget);
      expect(find.text(l.onboardingCompleteFailed), findsNothing);
      verify(datasource.completeOnboarding).called(1);
    });

    testWidgets('failure is reported to the injected logger', (tester) async {
      final datasource = _MockDatasource();
      when(datasource.completeOnboarding).thenThrow(Exception('disk full'));
      final logger = _MockAppLogger();
      await pumpPage(tester, datasource, logger: logger);
      await reachLastPage(tester);
      final l = labelsOf(tester);

      await tester.tap(find.text(l.onboardingGetStarted));
      await tester.pump();

      verify(
        () => logger.warning(
          'completeOnboarding failed',
          tag: 'onboarding',
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).called(1);
    });
  });
}
