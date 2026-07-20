import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/theme/theme_extensions.dart';

class AccountNoAccountFooterWidget extends StatelessWidget {
  const AccountNoAccountFooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = context.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'New to FamilyAdmin?',
              style: context.textTheme.bodyMedium?.copyWith(
                color: onSurface.withValues(alpha: 0.74),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Create a free account'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _AccountNoAccountFeatureItem(
              icon: Icons.lock_outline_rounded,
              label: 'Secure & private',
            ),
            _AccountNoAccountFeatureItem(
              icon: Icons.star_outline_rounded,
              label: 'Free to start',
            ),
            _AccountNoAccountFeatureItem(
              icon: Icons.group_rounded,
              label: 'Family plan',
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountNoAccountFeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AccountNoAccountFeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.colorScheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 20, color: context.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.74),
            ),
          ),
        ],
      ),
    );
  }
}
