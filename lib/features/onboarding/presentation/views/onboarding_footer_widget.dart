import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/theme/sand_palette.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class OnboardingFooterWidget extends StatelessWidget {
  final bool isLastPage;
  final VoidCallback onNext;

  const OnboardingFooterWidget({
    super.key,
    required this.isLastPage,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SandPalette.sand500, SandPalette.sand600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: SandPalette.sand500.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onNext,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLastPage ? l.onboardingGetStarted : l.onboardingNextStep,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isLastPage
                      ? Icons.auto_awesome_rounded
                      : Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
