import 'package:flutter/material.dart';
import 'package:house_mira_core/theme/sand_palette.dart';

class OnboardingPageWidget extends StatelessWidget {
  const OnboardingPageWidget({
    required this.title,
    required this.subtitle,
    required this.hero,
    required this.identifier,
    super.key,
  });
  final String title;
  final String subtitle;
  final Widget hero;

  /// Stable handle for the e2e suite (`onboarding-slide-1`…`3`).
  ///
  /// A `Semantics` container rather than a text match, so onboarding copy can
  /// change in `app_en.arb` without turning the suite red.
  final String identifier;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: identifier,
      container: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            SizedBox(height: 320, child: Center(child: hero)),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: SandPalette.sand700,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: SandPalette.sand400,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
