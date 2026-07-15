import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/theme/theme_extensions.dart';

class AccountHeaderWidget extends StatelessWidget {
  const AccountHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.colorScheme.primary;
    final onSurface = context.colorScheme.onSurface;
    final surface = context.colorScheme.surface;

    return Container(
      width: double.infinity,
      color: context.colorScheme.background,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.home_rounded, size: 24),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.more_horiz_rounded, size: 24),
              ),
            ],
          ),
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
                Image.network(
                  'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&q=80',
                  fit: BoxFit.cover,
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
            'Sarah Smith',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'sarah@smithfamily.com',
            style: context.textTheme.bodyMedium?.copyWith(
              color: onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.king_bed, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Family Admin',
                  style: context.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Plan',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Family Pro',
                        style: context.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Up to 8 members · Unlimited reminders',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Active',
                    style: context.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Text(
                'Manage',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
