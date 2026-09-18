import 'package:flutter/material.dart';
import 'package:house_mira/generated/app_localizations.dart';

class FamilyHeaderWidget extends StatelessWidget {

  const FamilyHeaderWidget({
    super.key,
    this.role,
    this.onNotificationsPressed,
    this.onProfilePressed,
  });
  final String? role;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onProfilePressed;

  static const _brown = Color(0xFF725C43);
  static const _cream = Color(0xFFF2EDE4);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (role == null) return const SizedBox.shrink();
    return Row(
      children: [
        const _HeaderIcon(icon: Icons.home_rounded),
        const SizedBox(width: 8),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton.filled(
              tooltip: l.peopleWidgetsFamilyHeaderNotificationsTooltip,
              onPressed: onNotificationsPressed,
              style: IconButton.styleFrom(
                backgroundColor: _cream,
                foregroundColor: _brown,
              ),
              icon: const Icon(Icons.notifications_rounded, size: 20),
            ),
            const Positioned(
              right: 8,
              top: 7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFC68B42),
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(dimension: 6),
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
        Semantics(
          button: true,
          label: l.peopleWidgetsFamilyHeaderProfileSemantics,
          child: InkWell(
            onTap: onProfilePressed,
            customBorder: const CircleBorder(),
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: _cream,
              child: Icon(
                Icons.person_rounded,
                color: Color(0xFF725C43),
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {

  const _HeaderIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFF725C43),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}
