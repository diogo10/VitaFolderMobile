import 'package:flutter/material.dart';
import 'package:house_mira/theme/sand_palette.dart';

class OnboardingPageWidget extends StatelessWidget {

  const OnboardingPageWidget({
    required this.title, required this.subtitle, required this.hero, super.key,
  });
  final String title;
  final String subtitle;
  final Widget hero;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
    );
  }
}
