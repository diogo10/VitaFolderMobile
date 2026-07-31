import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';
import 'package:vita_folder_mobile/theme/theme_extensions.dart';

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            hero,
            const SizedBox(height: 36),
            Text(
              AppLocalizations.of(context)!.onboardingFamilyCircleLabel,
              style: context.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.onSurface.withValues(alpha: 0.74),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.72),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
