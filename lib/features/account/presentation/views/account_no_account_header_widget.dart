import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/theme/theme_extensions.dart';

class AccountNoAccountHeaderWidget extends StatelessWidget {
  const AccountNoAccountHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = context.colorScheme.onSurface;
    final surface = context.colorScheme.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.home_rounded, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(child: _AccountNoAccountHeroWidget()),
        const SizedBox(height: 32),
        Text(
          'Your family, organised together',
          textAlign: TextAlign.center,
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Manage your circle, set reminders and collaborate as a family — all in one place.',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: onSurface.withValues(alpha: 0.72),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: const [
            _AccountNoAccountChip(label: 'Chores', icon: Icons.checklist_rtl),
            _AccountNoAccountChip(label: 'Appointments', icon: Icons.calendar_today_rounded),
            _AccountNoAccountChip(label: 'Family Circle', icon: Icons.groups_rounded),
          ],
        ),
      ],
    );
  }
}

class _AccountNoAccountHeroWidget extends StatelessWidget {
  const _AccountNoAccountHeroWidget();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final primary = colorScheme.primary;
    final onPrimary = colorScheme.onPrimary;
    final surface = colorScheme.surface;
    final surfaceContainerHighest = colorScheme.surfaceContainerHighest;

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [primary.withValues(alpha: 0.18), primary.withValues(alpha: 0.02)],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(48),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.family_restroom_rounded,
                  size: 72,
                  color: primary,
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 18,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.notifications_rounded, size: 28),
            ),
          ),
          Positioned(
            left: 18,
            top: 26,
            child: Row(
              children: [
                const _AccountNoAccountAvatar(label: 'A'),
                const SizedBox(width: 8),
                const _AccountNoAccountAvatar(label: 'T'),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: surface, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+3',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 18,
            left: 28,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.flare_rounded, size: 18, color: primary),
                  const SizedBox(width: 6),
                  Text(
                    'Family admin',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountNoAccountAvatar extends StatelessWidget {
  final String label;

  const _AccountNoAccountAvatar({required this.label});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: context.colorScheme.primary.withValues(alpha: 0.14),
      child: Text(
        label,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AccountNoAccountChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _AccountNoAccountChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
