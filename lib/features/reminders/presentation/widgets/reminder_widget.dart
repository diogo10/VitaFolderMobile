import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class ReminderWidget extends StatefulWidget {
  final ReminderEntity reminder;

  const ReminderWidget({super.key, required this.reminder});

  @override
  State<ReminderWidget> createState() => _ReminderWidgetState();
}

class _ReminderWidgetState extends State<ReminderWidget> {
  bool _actionsVisible = false;

  ReminderEntity get reminder => widget.reminder;

  void _toggleActions() {
    setState(() => _actionsVisible = !_actionsVisible);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final typeColor = _typeColor(colorScheme);
    final iconData = _typeIcon(reminder.type);
    final timeLabel = _extractTimeLabel(reminder.dueDate);
    final dueDateLabel = _extractDueDateLabel(reminder.dueDate, timeLabel);
    final l = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: _toggleActions,
      child: Card(
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
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0.25, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                              ),
                            ),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: _actionsVisible
                        ? _ActionButtons(
                            key: const ValueKey('actions'),
                            typeColor: typeColor,
                            onEdit: () => _onEdit(context),
                            onRemove: () => _onRemove(context),
                          )
                        : _TrailingChip(
                            key: ValueKey(timeLabel ?? 'allday'),
                            label: timeLabel ?? l.remindersLoadedSectionAllDay,
                            typeColor: typeColor,
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
                  if (reminder.status.isNotEmpty &&
                      reminder.status != 'pending')
                    _StatusChip(
                      status: reminder.status,
                      colorScheme: colorScheme,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onEdit(BuildContext context) {
    context.push('/create-reminder', extra: reminder.type);
  }

  Future<void> _onRemove(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<RemindersCubit>();
    final id = int.tryParse(reminder.id);
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.reminderDeleteDialogTitle),
        content: Text(l.reminderDeleteDialogMessage(reminder.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.reminderDeleteDialogConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cubit.removeReminder(id);
    }
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
    if (dueDate.trim().isEmpty) return null;

    final match = RegExp(
      r'(\d{1,2}:\d{2}(?:\s*(?:AM|PM|am|pm))?)',
    ).firstMatch(dueDate);
    if (match == null) return null;

    final value = match.group(0)?.trim();
    if (value == null || value.isEmpty) return null;

    return value;
  }

  String _extractDueDateLabel(String dueDate, String? timeLabel) {
    if (timeLabel == null) {
      return dueDate;
    }

    final datePortion = dueDate.replaceFirst(timeLabel, '').trim();
    final trimmed = datePortion
        .replaceAll(RegExp(r'^[\s·•\-]+|[\s·•\-]+$'), '')
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

class _TrailingChip extends StatelessWidget {
  final String label;
  final Color typeColor;

  const _TrailingChip({
    super.key,
    required this.label,
    required this.typeColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _trailingSlotWidth,
      height: _trailingSlotHeight,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: typeColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Color typeColor;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _ActionButtons({
    super.key,
    required this.typeColor,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _trailingSlotWidth,
      height: _trailingSlotHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onEdit,
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_rounded),
            iconSize: 18,
            color: typeColor,
            style: IconButton.styleFrom(
              backgroundColor: typeColor.withValues(alpha: 0.16),
              minimumSize: const Size(_trailingButtonSize, _trailingButtonSize),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove',
            icon: const Icon(Icons.delete_rounded),
            iconSize: 18,
            color: typeColor,
            style: IconButton.styleFrom(
              backgroundColor: typeColor.withValues(alpha: 0.16),
              minimumSize: const Size(_trailingButtonSize, _trailingButtonSize),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

const double _trailingSlotHeight = 36;
const double _trailingSlotWidth = 80;
const double _trailingButtonSize = 36;

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
