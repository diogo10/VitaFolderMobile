import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/features/onboarding/presentation/onboarding_palette.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class OnboardingHeaderWidget extends StatelessWidget {
  final VoidCallback onSkip;

  const OnboardingHeaderWidget({super.key, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: OnboardingPalette.sand500,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.home_rounded,
              size: 20,
              color: OnboardingPalette.sand50,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onSkip,
            child: Text(
              AppLocalizations.of(context)!.onboardingSkip,
              style: const TextStyle(
                color: OnboardingPalette.sand400,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
