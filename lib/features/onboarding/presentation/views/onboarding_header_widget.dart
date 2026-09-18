import 'package:flutter/material.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/sand_palette.dart';

class OnboardingHeaderWidget extends StatelessWidget {

  const OnboardingHeaderWidget({required this.onSkip, super.key});
  final VoidCallback onSkip;

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
              color: SandPalette.sand500,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.home_rounded,
              size: 20,
              color: SandPalette.sand50,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onSkip,
            child: Text(
              AppLocalizations.of(context)!.onboardingSkip,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: SandPalette.sand400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
