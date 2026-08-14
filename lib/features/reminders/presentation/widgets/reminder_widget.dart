import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class ReminderWidget extends StatelessWidget {
  final ReminderEntity reminder;

  const ReminderWidget({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final typeColor = _typeColor(colorScheme);
    final iconData = _typeIcon(reminder.type);
    final timeLabel = _extractTimeLabel(reminder.dueDate);
    final dueDateLabel = _extractDueDateLabel(reminder.dueDate, timeLabel);
    final l = AppLocalizations.of(context)!;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(iconData, size: 24, color: typeColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    reminder.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (timeLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: typeColor,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      l.remindersLoadedSectionAllDay,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: typeColor,
                      ),
                    ),
                  ),
              ],
            ),
            if (reminder.body.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                reminder.body,
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (dueDateLabel.isNotEmpty)
                  _MetaItem(
                    icon: Icons.event_rounded,
                    label: dueDateLabel,
                    textColor: colorScheme.onSurfaceVariant,
                  ),
                if (reminder.repeatRule.isNotEmpty &&
                    reminder.repeatRule != 'never')
                  _MetaItem(
                    icon: Icons.repeat_rounded,
                    label: _repeatLabel(reminder.repeatRule, l),
                    textColor: colorScheme.onSurfaceVariant,
                  ),
                if (reminder.createdBy.isNotEmpty)
                  _MetaItem(
                    icon: Icons.person_rounded,
                    label: reminder.createdBy,
                    textColor: colorScheme.onSurfaceVariant,
                  ),
                if (reminder.status.isNotEmpty && reminder.status != 'pending')
                  _StatusChip(
                    status: reminder.status,
                    colorScheme: colorScheme,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(ColorScheme colorScheme) {
    switch (reminder.type) {
      case ReminderType.renewal:
        return const Color(0xFF4087C3).withValues(alpha: 0.6);
      case ReminderType.appointment:
        return const Color(0xFF4076C3).withValues(alpha: 0.6);
      case ReminderType.vaccine:
        return const Color(0xFF6C63B8).withValues(alpha: 0.6);
      case ReminderType.reimbursement:
        return const Color(0xFF4CAF7D).withValues(alpha: 0.6);
      case ReminderType.birthday:
        return const Color(0xFFD46D8B).withValues(alpha: 0.6);
      case ReminderType.chores:
        return const Color(0xFFB68C3B).withValues(alpha: 0.6);
      case ReminderType.custom:
        return colorScheme.primary.withValues(alpha: 0.6);
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

  String _extractDueDateLabel(String dueDate, String? timeLabel) {
    if (timeLabel == null) {
      return dueDate;
    }

    final trimmed = dueDate
        .replaceFirst(timeLabel, '')
        .replaceAll(RegExp(r'[·•\-]'), '')
        .trim();
    return trimmed.isEmpty ? dueDate : trimmed;
  }

  String _repeatLabel(String repeatRule, AppLocalizations l) {
    switch (repeatRule) {
      case 'daily':
        return l.createReminderRepeatDaily;
      case 'weekly':
        return l.createReminderRepeatWeekly;
      case 'monthly':
        return l.createReminderRepeatMonthly;
      default:
        return l.createReminderRepeatNever;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final ColorScheme colorScheme;

  const _StatusChip({required this.status, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final (label, background, foreground) = switch (status) {
      'sent' => (
        l.reminderStatusSent,
        const Color(0xFFE3F2FD),
        const Color(0xFF1E5FA8),
      ),
      'done' => (
        l.reminderStatusDone,
        const Color(0xFFE8F5E9),
        const Color(0xFF2E7D32),
      ),
      'dismissed' => (
        l.reminderStatusDismissed,
        const Color(0xFFF3E5F5),
        const Color(0xFF6A1B9A),
      ),
      'cancelled' => (
        l.reminderStatusCancelled,
        const Color(0xFFFDECEA),
        const Color(0xFFC62828),
      ),
      _ => (
        l.reminderStatusPending,
        const Color(0xFFFFF3E0),
        const Color(0xFFE65100),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;

  const _MetaItem({
    required this.icon,
    required this.label,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: textColor.withValues(alpha: 0.8)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, color: textColor)),
      ],
    );
  }
}
