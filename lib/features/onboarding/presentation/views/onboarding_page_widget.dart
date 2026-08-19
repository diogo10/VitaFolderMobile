import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/features/onboarding/presentation/onboarding_palette.dart';

class OnboardingPageWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget hero;

  const OnboardingPageWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.hero,
  });

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
            style: const TextStyle(
              color: OnboardingPalette.sand700,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: OnboardingPalette.sand400,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
