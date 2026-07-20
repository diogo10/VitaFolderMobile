import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';
import 'package:vita_folder_mobile/theme/theme_extensions.dart';

class OnboardingHeaderWidget extends StatelessWidget {
  final VoidCallback onSkip;

  const OnboardingHeaderWidget({super.key, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 8),
      child: Row(
        children: [
          const _OnboardingAvatarCluster(),
          const Spacer(),
          TextButton(
            onPressed: onSkip,
            child: Text(AppLocalizations.of(context)!.onboardingSkip),
          ),
        ],
      ),
    );
  }
}

class _OnboardingAvatarCluster extends StatelessWidget {
  const _OnboardingAvatarCluster();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _OnboardingAvatar(label: 'A'),
        const SizedBox(width: 10),
        _OnboardingAvatar(label: 'T'),
      ],
    );
  }
}

class _OnboardingAvatar extends StatelessWidget {
  final String label;

  const _OnboardingAvatar({required this.label});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: context.colorScheme.surface,
      child: Text(
        label,
        style: context.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: context.colorScheme.onSurface,
        ),
      ),
    );
  }
}
