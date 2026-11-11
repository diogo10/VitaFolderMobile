import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira_core/generated/app_localizations.dart';
import 'package:house_mira_onboarding/presentation/views/onboarding_view.dart';

/// Pins the semantics identifiers the device e2e suite locates by
/// (`e2e/tests/onboarding.e2e.ts`). They are the contract between the app and
/// an external runner: renaming or dropping one fails on a real emulator with a
/// much slower feedback loop, so it is pinned here first.
void main() {
  Future<void> pumpOnboarding(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingView(onComplete: () {}),
      ),
    );
    await tester.pump();
  }

  /// The heroes animate forever, so `pumpAndSettle` never settles; pump past
  /// the 400 ms page transition instead.
  Future<void> settleSlide(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Runs [body] with the semantics tree enabled. The handle is disposed before
  /// the test ends: `addTearDown` runs after the framework verifies that no
  /// handle is still active.
  Future<void> withSemantics(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await body();
    } finally {
      handle.dispose();
    }
  }

  group('OnboardingView semantics identifiers', () {
    testWidgets('slide 1 exposes skip, slide and next identifiers', (
      tester,
    ) async {
      await withSemantics(tester, () async {
        await pumpOnboarding(tester);

        expect(
          find.bySemanticsIdentifier('onboarding-slide-1'),
          findsOneWidget,
        );
        expect(find.bySemanticsIdentifier('onboarding-skip'), findsOneWidget);
        expect(
          find.bySemanticsIdentifier('onboarding-cta-next'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsIdentifier('onboarding-cta-finish'),
          findsNothing,
        );
        expect(find.bySemanticsIdentifier('onboarding-slide-2'), findsNothing);
      });
    });

    testWidgets(
      'next moves the slide identifier and flips the CTA at the end',
      (
        tester,
      ) async {
        await withSemantics(tester, () async {
          await pumpOnboarding(tester);

          await tester.tap(find.text('Next Step'));
          await settleSlide(tester);
          expect(
            find.bySemanticsIdentifier('onboarding-slide-2'),
            findsOneWidget,
          );
          expect(
            find.bySemanticsIdentifier('onboarding-slide-1'),
            findsNothing,
          );
          expect(
            find.bySemanticsIdentifier('onboarding-cta-next'),
            findsOneWidget,
          );

          await tester.tap(find.text('Next Step'));
          await settleSlide(tester);
          expect(
            find.bySemanticsIdentifier('onboarding-slide-3'),
            findsOneWidget,
          );
          expect(
            find.bySemanticsIdentifier('onboarding-cta-finish'),
            findsOneWidget,
          );
          expect(
            find.bySemanticsIdentifier('onboarding-cta-next'),
            findsNothing,
          );
        });
      },
    );

    testWidgets('skip jumps to the last slide', (tester) async {
      await withSemantics(tester, () async {
        await pumpOnboarding(tester);

        await tester.tap(find.bySemanticsIdentifier('onboarding-skip'));
        await settleSlide(tester);

        expect(
          find.bySemanticsIdentifier('onboarding-slide-3'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsIdentifier('onboarding-cta-finish'),
          findsOneWidget,
        );
      });
    });
  });
}
