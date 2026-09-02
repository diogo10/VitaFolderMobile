import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/onboarding/presentation/views/onboarding_footer_widget.dart';
import 'package:house_mira/features/onboarding/presentation/views/onboarding_progress_widget.dart';
import 'package:house_mira/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:house_mira/generated/app_localizations.dart';

void main() {
  Future<void> pumpOnboardingView(
    WidgetTester tester, {
    VoidCallback? onComplete,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingView(onComplete: onComplete ?? () {}),
      ),
    );
    await tester.pump();
  }

  List<AnimatedContainer> dots(WidgetTester tester) => tester
      .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
      .where(
        (w) => w.constraints?.minWidth == 8 || w.constraints?.minWidth == 24,
      )
      .toList();

  group('OnboardingView', () {
    testWidgets('renders header, dots and gradient CTA on first page', (
      tester,
    ) async {
      await pumpOnboardingView(tester);

      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next Step'), findsOneWidget);
      expect(find.text('Get Started'), findsNothing);
      expect(find.byType(OnboardingProgressWidget), findsOneWidget);
      expect(find.byType(OnboardingFooterWidget), findsOneWidget);
      expect(find.text('Your Family,\nIn One Place'), findsOneWidget);
    });

    testWidgets('marks active dot as the wide pill', (tester) async {
      await pumpOnboardingView(tester);

      final dotList = dots(tester);
      expect(dotList, hasLength(3));

      final active = dotList
          .where((w) => w.constraints?.minWidth == 24)
          .toList();
      expect(active, hasLength(1));

      await tester.tap(find.text('Next Step'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final after = dots(tester);
      expect(after.where((w) => w.constraints?.minWidth == 24), hasLength(1));
    });

    testWidgets('swaps CTA label to Get Started on last page', (tester) async {
      await pumpOnboardingView(tester);

      await tester.tap(find.text('Next Step'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Next Step'), findsOneWidget);

      await tester.tap(find.text('Next Step'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Secure & Private\nBy Design'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Next Step'), findsNothing);
    });

    testWidgets('skip jumps to last page without completing', (tester) async {
      var completed = false;
      await pumpOnboardingView(tester, onComplete: () => completed = true);

      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Secure & Private\nBy Design'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(completed, isFalse);
    });

    testWidgets('tapping Get Started triggers onComplete', (tester) async {
      var completed = false;
      await pumpOnboardingView(tester, onComplete: () => completed = true);

      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Get Started'));
      await tester.pump();

      expect(completed, isTrue);
    });
  });
}
