import 'package:flutter/material.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/theme_extensions.dart';

class HomeEmptyInviteCardWidget extends StatelessWidget {
  final VoidCallback onSharePressed;

  const HomeEmptyInviteCardWidget({
    super.key,
    required this.onSharePressed,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.homeEmptyInviteInviteParentTitle,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.homeEmptyInviteInviteParentSubtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onSharePressed,
            icon: const Icon(
              Icons.share_rounded,
              size: 18,
            ),
            label: Text(l.homeEmptyInviteShareButton),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: context.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
