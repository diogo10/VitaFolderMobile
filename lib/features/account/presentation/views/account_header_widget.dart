import 'package:flutter/material.dart';
import 'package:house_mira/theme/theme_extensions.dart';

class AccountHeaderWidget extends StatelessWidget {
  const AccountHeaderWidget({
    required this.userName,
    required this.email,
    super.key,
  });
  final String userName;
  final String email;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.colorScheme.onSurface;

    return Container(
      width: double.infinity,
      color: context.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            userName,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          Text(
            email,
            style: context.textTheme.bodyMedium?.copyWith(
              color: onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
