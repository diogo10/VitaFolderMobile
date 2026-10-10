import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/router/app_routes.dart';
import 'package:house_mira/features/onboarding/data/datasource/onboarding_local_datasource.dart';
import 'package:house_mira/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:house_mira/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockDatasource extends Mock implements OnboardingLocalDatasource {}

GoRouter testRouter(OnboardingLocalDatasource datasource) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => OnboardingPage(datasource: datasource),
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
  OnboardingLocalDatasource datasource,
) async {
  final router = testRouter(datasource);
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
  });
}
