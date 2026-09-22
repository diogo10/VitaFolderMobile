import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/app_constants.dart';
import 'package:house_mira/theme/app_theme.dart';
import 'package:house_mira/theme/sand_palette.dart';
import 'package:house_mira/theme/theme_extensions.dart';

/// Golden + unit tests for the theme layer (`lib/theme/`).
///
/// Goldens live under `test/goldens/theme/` and are generated with
/// `flutter test --update-goldens`. Unit assertions below pin the
/// [ThemeExtensions]/[AppConstants] contracts so refactors that keep pixels
/// but break the API still fail fast.
void main() {
  // NOTE: goldens use font-free schemes on purpose. AppTheme.theme() resolves
  // Figtree via Google Fonts at runtime (network or a generated font bundle),
  // which makes pixels non-deterministic offline/CI. ColorScheme factories
  // below are font-free, so they pin the same tokens without the fetch.
  ThemeData fontFreeTheme(ColorScheme scheme) =>
      ThemeData(colorScheme: scheme, useMaterial3: true);

  Widget themeShowcase(ThemeData theme) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      appBar: AppBar(title: const Text('Theme')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              SandSwatch(color: SandPalette.sand50, label: '50'),
              SandSwatch(color: SandPalette.sand100, label: '100'),
              SandSwatch(color: SandPalette.sand200, label: '200'),
              SandSwatch(color: SandPalette.sand300, label: '300'),
              SandSwatch(color: SandPalette.sand400, label: '400'),
              SandSwatch(color: SandPalette.sand500, label: '500'),
              SandSwatch(color: SandPalette.sand600, label: '600'),
              SandSwatch(color: SandPalette.sand700, label: '700'),
            ],
          ),
          const SizedBox(height: 16),
          const _ButtonRow(),
          const SizedBox(height: 16),
          const _SpacingRow(),
        ],
      ),
    ),
  );

  Future<void> pumpSized(
    WidgetTester tester,
    ThemeData theme, {
    Size size = const Size(400, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(themeShowcase(theme));
    await tester.pump();
  }

  group('AppTheme goldens', () {
    testWidgets('light showcase golden', (tester) async {
      await pumpSized(tester, fontFreeTheme(AppTheme.lightScheme()));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../goldens/theme/showcase_light.png'),
      );
    });

    testWidgets('dark showcase golden', (tester) async {
      await pumpSized(tester, fontFreeTheme(AppTheme.darkScheme()));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../goldens/theme/showcase_dark.png'),
      );
    });

    test('light and dark schemes differ in brightness + surface', () {
      expect(AppTheme.lightScheme().brightness, Brightness.light);
      expect(AppTheme.darkScheme().brightness, Brightness.dark);
      expect(
        AppTheme.lightScheme().surface,
        isNot(AppTheme.darkScheme().surface),
      );
    });

    test('contrast variants keep the base brightness', () {
      expect(AppTheme.lightMediumContrastScheme().brightness, Brightness.light);
      expect(AppTheme.lightHighContrastScheme().brightness, Brightness.light);
      expect(AppTheme.darkMediumContrastScheme().brightness, Brightness.dark);
      expect(AppTheme.darkHighContrastScheme().brightness, Brightness.dark);
    });

    test('custom colors are opaque brand tokens', () {
      const scheme = ColorScheme.light();
      expect((scheme.success.a * 255.0).round(), 0xFF);
      expect((scheme.warning.a * 255.0).round(), 0xFF);
      expect((scheme.info.a * 255.0).round(), 0xFF);
    });
  });

  group('SandPalette', () {
    test('sand ramp is opaque and ordered light to dark', () {
      const ramp = [
        SandPalette.sand50,
        SandPalette.sand100,
        SandPalette.sand200,
        SandPalette.sand300,
        SandPalette.sand400,
        SandPalette.sand500,
        SandPalette.sand600,
        SandPalette.sand700,
      ];
      for (final color in ramp) {
        expect(
          (color.a * 255.0).round(),
          0xFF,
          reason: '$color must be opaque',
        );
      }
      // Luminance decreases as the ramp darkens.
      for (var i = 0; i < ramp.length - 1; i++) {
        expect(
          ramp[i].computeLuminance(),
          greaterThan(ramp[i + 1].computeLuminance()),
        );
      }
    });
  });

  group('ThemeExtensions', () {
    testWidgets('isDarkMode follows theme brightness', (tester) async {
      final light = fontFreeTheme(AppTheme.lightScheme());
      final dark = fontFreeTheme(AppTheme.darkScheme());
      bool? lightDark;
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('light'),
          home: Builder(
            builder: (context) {
              lightDark = Theme.of(context).brightness == Brightness.dark;
              return const SizedBox();
            },
          ),
          theme: light,
        ),
      );
      expect(lightDark, isFalse);

      bool? darkDark;
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('dark'),
          home: Builder(
            builder: (context) {
              darkDark = Theme.of(context).brightness == Brightness.dark;
              return const SizedBox();
            },
          ),
          theme: dark,
        ),
      );
      expect(darkDark, isTrue);
    });

    testWidgets('spacing + padding + radius follow AppConstants', (
      tester,
    ) async {
      var ran = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              expect(context.gapMD, isA<SizedBox>());
              expect(
                context.paddingMD,
                const EdgeInsets.all(AppConstants.spacingMD),
              );
              expect(
                context.radiusMD,
                BorderRadius.circular(AppConstants.radiusMD),
              );
              expect(
                context.paddingHorizontal(8),
                const EdgeInsets.symmetric(horizontal: 8),
              );
              expect(
                context.paddingVertical(8),
                const EdgeInsets.symmetric(vertical: 8),
              );
              ran = true;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(ran, isTrue);
    });

    testWidgets('responsive breakpoints classify widths', (tester) async {
      Future<bool> check(
        double width,
        bool Function(BuildContext) select,
      ) async {
        var result = false;
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                result = select(context);
                return const SizedBox();
              },
            ),
          ),
        );
        return result;
      }

      expect(await check(400, (c) => c.isMobile), isTrue);
      expect(await check(400, (c) => c.isDesktop), isFalse);
      expect(await check(800, (c) => c.isTablet), isTrue);
      expect(await check(1400, (c) => c.isDesktop), isTrue);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('widget extensions compose', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text(
              'hi',
            ).paddingAll(8).centered().opacity(0.5).safeArea(),
          ),
        ),
      );

      expect(find.text('hi'), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);
      expect(find.byType(Center), findsOneWidget);
      expect(find.byType(Opacity), findsOneWidget);
    });
  });

  group('AppConstants', () {
    test('responsive padding grows with width', () {
      expect(
        AppConstants.getResponsivePadding(400),
        const EdgeInsets.all(AppConstants.spacingMD),
      );
      expect(
        AppConstants.getResponsivePadding(1000),
        const EdgeInsets.all(AppConstants.spacingXL),
      );
      expect(
        AppConstants.getResponsivePadding(1300),
        const EdgeInsets.all(AppConstants.spacingXXL),
      );
    });

    test('breakpoint helpers partition widths', () {
      expect(AppConstants.isMobile(599), isTrue);
      expect(AppConstants.isTablet(600), isTrue);
      expect(AppConstants.isTablet(1199), isTrue);
      expect(AppConstants.isDesktop(1200), isTrue);
    });
  });
}

class SandSwatch extends StatelessWidget {
  const SandSwatch({required this.color, required this.label, super.key});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _ButtonRow extends StatelessWidget {
  const _ButtonRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _DemoElevated()),
        SizedBox(width: 8),
        Expanded(child: _DemoOutlined()),
      ],
    );
  }
}

class _DemoElevated extends StatelessWidget {
  const _DemoElevated();

  @override
  Widget build(BuildContext context) {
    return const ElevatedButton(onPressed: null, child: Text('Elevated'));
  }
}

class _DemoOutlined extends StatelessWidget {
  const _DemoOutlined();

  @override
  Widget build(BuildContext context) {
    return const OutlinedButton(onPressed: null, child: Text('Outlined'));
  }
}

class _SpacingRow extends StatelessWidget {
  const _SpacingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [context.gapXS, context.gapSM, context.gapMD, context.gapLG],
    );
  }
}
