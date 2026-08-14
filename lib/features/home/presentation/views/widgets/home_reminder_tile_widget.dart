import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';

class HomeReminderTileWidget extends StatelessWidget {
  final ReminderEntity reminder;

  const HomeReminderTileWidget({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final typeColor = _typeColor(colorScheme);
    final iconData = _typeIcon(reminder.type);
    final timeLabel = _extractTimeLabel(reminder.dueDate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(iconData, size: 22, color: typeColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (reminder.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reminder.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (timeLabel != null) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                timeLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: typeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _typeColor(ColorScheme colorScheme) {
    switch (reminder.type) {
      case ReminderType.renewal:
        return const Color(0xFF4087C3);
      case ReminderType.appointment:
        return const Color(0xFF4076C3);
      case ReminderType.vaccine:
        return const Color(0xFF6C63B8);
      case ReminderType.reimbursement:
        return const Color(0xFF4CAF7D);
      case ReminderType.birthday:
        return const Color(0xFFD46D8B);
      case ReminderType.chores:
        return const Color(0xFFB68C3B);
      case ReminderType.custom:
        return colorScheme.primary;
    }
  }

  IconData _typeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.renewal:
        return Icons.autorenew_rounded;
      case ReminderType.appointment:
        return Icons.event_available_rounded;
      case ReminderType.vaccine:
        return Icons.vaccines_rounded;
      case ReminderType.reimbursement:
        return Icons.receipt_long_rounded;
      case ReminderType.birthday:
        return Icons.cake_rounded;
      case ReminderType.chores:
        return Icons.cleaning_services_rounded;
      case ReminderType.custom:
        return Icons.sticky_note_2_rounded;
    }
  }

  String? _extractTimeLabel(String dueDate) {
    final match = RegExp(
      r'(\d{1,2}:\d{2}\s*(AM|PM|am|pm)|\d{1,2}\s*(AM|PM|am|pm))',
    ).firstMatch(dueDate);
    return match?.group(0)?.trim();
  }
}
