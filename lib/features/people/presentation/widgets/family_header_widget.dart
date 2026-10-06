import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/router/app_routes.dart';
import 'package:house_mira/generated/app_localizations.dart';

class FamilyHeaderWidget extends StatelessWidget {
  const FamilyHeaderWidget({
    super.key,
    this.role,
    this.showNotificationIcon = true,
    this.showProfileIcon = true,
  });
  final String? role;
  final bool showNotificationIcon;
  final bool showProfileIcon;

  static const _brown = Color(0xFF725C43);
  static const _cream = Color(0xFFF2EDE4);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (!showNotificationIcon && !showProfileIcon) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        const SizedBox(width: 8),
        const Spacer(),
        if (showNotificationIcon) ...[
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton.filled(
                tooltip: l.peopleWidgetsFamilyHeaderNotificationsTooltip,
                onPressed: () => context.go(AppRoutes.reminders),
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
        ],
        if (showProfileIcon)
          Semantics(
            button: true,
            label: l.peopleWidgetsFamilyHeaderProfileSemantics,
            child: InkWell(
              onTap: () => context.go(AppRoutes.account),
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
