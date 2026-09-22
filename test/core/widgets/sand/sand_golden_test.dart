import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/widgets/sand/google_g_icon.dart';
import 'package:house_mira/core/widgets/sand/sand_brand_mark.dart';
import 'package:house_mira/core/widgets/sand/sand_header.dart';
import 'package:house_mira/core/widgets/sand/sand_primary_button.dart';
import 'package:house_mira/core/widgets/sand/sand_social_button.dart';
import 'package:house_mira/core/widgets/sand/sand_text_field.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/app_theme.dart';

/// Golden tests for the sand design system (`lib/core/widgets/sand/`).
///
/// Run with `flutter test --update-goldens` to (re)generate baselines under
/// `test/goldens/sand/`. CI runs without the flag so pixel drift fails.
void main() {
  // NOTE: sand goldens deliberately avoid AppTheme.lightTheme/darkTheme:
  // AppTheme.theme() resolves Figtree via Google Fonts at runtime, which
  // needs the network (or a `flutter pub run google_fonts:generate` bundle).
  // A plain Material scheme keeps pixels deterministic offline and in CI.
  ThemeData sandTestTheme() =>
      ThemeData(colorScheme: AppTheme.lightScheme(), useMaterial3: true);

  Widget sandApp(Widget child, {ThemeData? theme}) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme ?? sandTestTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );

  Future<void> pumpSized(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(400, 800),
    ThemeData? theme,
  }) async {
    final resolved = theme ?? sandTestTheme();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(sandApp(child, theme: resolved));
    await tester.pump();
  }

  group('SandPrimaryButton', () {
    testWidgets('default variant golden', (tester) async {
      await pumpSized(
        tester,
        const SandPrimaryButton(label: 'Continue', icon: Icons.arrow_forward),
      );

      await expectLater(
        find.byType(SandPrimaryButton),
        matchesGoldenFile('../../../goldens/sand/primary_button_default.png'),
      );
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('loading variant golden', (tester) async {
      await pumpSized(
        tester,
        const SandPrimaryButton(
          label: 'Continue',
          icon: Icons.arrow_forward,
          isLoading: true,
          onPressed: null,
        ),
      );

      await expectLater(
        find.byType(SandPrimaryButton),
        matchesGoldenFile('../../../goldens/sand/primary_button_loading.png'),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disabled variant golden', (tester) async {
      await pumpSized(
        tester,
        const SandPrimaryButton(label: 'Continue', icon: Icons.arrow_forward),
      );

      await expectLater(
        find.byType(SandPrimaryButton),
        matchesGoldenFile('../../../goldens/sand/primary_button_disabled.png'),
      );
    });

    testWidgets('tap is ignored while loading', (tester) async {
      var tapped = false;
      await pumpSized(
        tester,
        SandPrimaryButton(
          label: 'Continue',
          icon: Icons.arrow_forward,
          isLoading: true,
          onPressed: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(SandPrimaryButton));
      await tester.pump();

      expect(tapped, isFalse);
    });
  });

  group('SandSocialButton', () {
    testWidgets('google variant golden', (tester) async {
      await pumpSized(
        tester,
        const SandSocialButton(
          icon: GoogleGIcon(),
          label: 'Continue with Google',
        ),
      );

      await expectLater(
        find.byType(SandSocialButton),
        matchesGoldenFile('../../../goldens/sand/social_button_google.png'),
      );
      expect(find.text('Continue with Google'), findsOneWidget);
    });
  });

  group('SandHeader', () {
    testWidgets('default golden', (tester) async {
      await pumpSized(
        tester,
        SandHeader(title: 'Reminders', onBack: () {}),
      );

      await expectLater(
        find.byType(SandHeader),
        matchesGoldenFile('../../../goldens/sand/header_default.png'),
      );
      expect(find.text('Reminders'), findsOneWidget);
    });

    testWidgets('with trailing action golden', (tester) async {
      await pumpSized(
        tester,
        SandHeader(
          title: 'Reminders',
          onBack: () {},
          trailing: const Icon(Icons.add),
        ),
      );

      await expectLater(
        find.byType(SandHeader),
        matchesGoldenFile('../../../goldens/sand/header_trailing.png'),
      );
    });

    testWidgets('back button invokes onBack', (tester) async {
      var backed = false;
      await pumpSized(
        tester,
        SandHeader(title: 'Reminders', onBack: () => backed = true),
      );

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pump();

      expect(backed, isTrue);
    });
  });

  group('SandLabeledField', () {
    testWidgets('default golden', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpSized(
        tester,
        SandLabeledField(
          controller: controller,
          label: 'Email',
          hint: 'you@example.com',
          prefixIcon: Icons.email_outlined,
        ),
      );

      await expectLater(
        find.byType(SandLabeledField),
        matchesGoldenFile('../../../goldens/sand/labeled_field_default.png'),
      );
    });
  });

  group('SandBrandMark', () {
    testWidgets('default golden', (tester) async {
      await pumpSized(tester, const SandBrandMark());

      await expectLater(
        find.byType(SandBrandMark),
        matchesGoldenFile('../../../goldens/sand/brand_mark.png'),
      );
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    });
  });
}
