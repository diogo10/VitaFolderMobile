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
    final primaryColor = context.colorScheme.primary;
    final onSurface = context.colorScheme.onSurface;
    final surface = context.colorScheme.surface;

    return Container(
      width: double.infinity,
      color: context.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(32),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(
                  color: Colors.blue,
                  child: Icon(
                    Icons.person_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: surface, width: 3),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
