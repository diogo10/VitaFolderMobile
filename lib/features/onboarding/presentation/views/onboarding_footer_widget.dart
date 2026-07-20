import 'package:flutter/material.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: onNext,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLastPage
                    ? AppLocalizations.of(context)!.onboardingGetStarted
                    : AppLocalizations.of(context)!.onboardingNext,
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
