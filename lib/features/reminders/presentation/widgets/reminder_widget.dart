import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/utils/reminder_date_utils.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/sand_palette.dart';

class ReminderWidget extends StatefulWidget {
  const ReminderWidget({
    required this.reminder,
    super.key,
    this.isFutureDay = false,
  });
  final ReminderEntity reminder;
  final bool isFutureDay;

  @override
  State<ReminderWidget> createState() => _ReminderWidgetState();
}

class _ReminderWidgetState extends State<ReminderWidget> {
  ReminderEntity get reminder => widget.reminder;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final typeColors = _getTypeColors(reminder.type);
    final iconData = _typeIcon(reminder.type);
    final timeLabel = ReminderDateUtils.extractTimeLabel(reminder.dueDate);
    final hasDueDate = ReminderDateUtils.hasDueDate(reminder.dueDate);
    final repeatLabel = _repeatLabel(reminder.repeatRule, l);
    final description = _buildDescription(repeatLabel, timeLabel, l);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: _getBorderColor()),
      ),
      elevation: 0,
      shadowColor: SandPalette.sand500.withValues(alpha: 0.10),
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showMenu(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: SandPalette.sand500.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconContainer(
                  icon: iconData,
                  iconColor: typeColors.iconColor,
                  bgColor: typeColors.bgColor,
                  borderColor: typeColors.borderColor,
                  badgeIcon: _typeBadgeIcon(reminder.type),
                  badgeColor: typeColors.badgeColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: SandPalette.sand700,
                          height: 1.3,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: SandPalette.sand400,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (reminder.body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          reminder.body,
                          style: const TextStyle(
                            fontSize: 12,
                            color: SandPalette.sand400,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _AssigneeRow(
                        assigneeName: reminder.createdBy,
                        assigneeColor: _getAssigneeColor(reminder.type),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _TrailingSection(
                  timeLabel: timeLabel,
                  allDayLabel: l.remindersLoadedSectionAllDay,
                  noDateLabel: l.remindersLoadedSectionNoDate,
                  hasDueDate: hasDueDate,
                  typeColors: typeColors,
                  onMenuPressed: () => _showMenu(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final cubit = context.read<RemindersCubit>();
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        useRootNavigator: true,
        builder: (context) => _ReminderMenuSheet(
          reminder: reminder,
          cubit: cubit,
          onEdit: () async {
            Navigator.of(context).pop();
            await context.push('/create-reminder', extra: reminder);
          },
          onRemove: () async {
            Navigator.of(context).pop();
            await _onRemove(cubit);
          },
        ),
      ),
    );
  }

  Future<void> _onRemove(RemindersCubit cubit) async {
    final l = AppLocalizations.of(context)!;
    final id = reminder.id;

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

  _TypeColors _getTypeColors(ReminderType type) {
    switch (type) {
      case ReminderType.chores:
        return const _TypeColors(
          iconColor: ReminderTypeColors.chores500,
          bgColor: ReminderTypeColors.chores50,
          borderColor: ReminderTypeColors.chores100,
          badgeColor: ReminderTypeColors.chores400,
          chipBgColor: ReminderTypeColors.chores100,
          chipTextColor: ReminderTypeColors.chores600,
        );
      case ReminderType.appointment:
        return const _TypeColors(
          iconColor: ReminderTypeColors.appts500,
          bgColor: ReminderTypeColors.appts50,
          borderColor: ReminderTypeColors.appts100,
          badgeColor: ReminderTypeColors.appts400,
          chipBgColor: ReminderTypeColors.appts100,
          chipTextColor: ReminderTypeColors.appts600,
        );
      case ReminderType.birthday:
        return const _TypeColors(
          iconColor: ReminderTypeColors.bday400,
          bgColor: ReminderTypeColors.bday50,
          borderColor: ReminderTypeColors.bday100,
          badgeColor: ReminderTypeColors.bday400,
          chipBgColor: ReminderTypeColors.bday100,
          chipTextColor: ReminderTypeColors.bday600,
        );
      case ReminderType.renewal:
        return const _TypeColors(
          iconColor: Color(0xFF4087C3),
          bgColor: Color(0xFFE3F2FD),
          borderColor: Color(0xFFBBDEFB),
          badgeColor: Color(0xFF42A5F5),
          chipBgColor: Color(0xFFBBDEFB),
          chipTextColor: Color(0xFF1E88E5),
        );
      case ReminderType.vaccine:
        return const _TypeColors(
          iconColor: Color(0xFF6C63B8),
          bgColor: Color(0xFFEDE7F6),
          borderColor: Color(0xFFD1C4E9),
          badgeColor: Color(0xFF7E57C2),
          chipBgColor: Color(0xFFD1C4E9),
          chipTextColor: Color(0xFF5E35B1),
        );
      case ReminderType.reimbursement:
        return const _TypeColors(
          iconColor: Color(0xFF4CAF7D),
          bgColor: Color(0xFFE8F5E9),
          borderColor: Color(0xFFC8E6C9),
          badgeColor: Color(0xFF66BB6A),
          chipBgColor: Color(0xFFC8E6C9),
          chipTextColor: Color(0xFF388E3C),
        );
      case ReminderType.custom:
        final primary = Theme.of(context).colorScheme.primary;
        return _TypeColors(
          iconColor: primary,
          bgColor: primary.withValues(alpha: 0.16),
          borderColor: primary.withValues(alpha: 0.3),
          badgeColor: primary,
          chipBgColor: primary.withValues(alpha: 0.16),
          chipTextColor: primary,
        );
    }
  }

  Color _getBorderColor() {
    if (reminder.type == ReminderType.birthday) {
      return ReminderTypeColors.bday100;
    }
    if (widget.isFutureDay) {
      return SandPalette.sand200;
    }
    return SandPalette.sand100;
  }

  Color _getAssigneeColor(ReminderType type) {
    if (type == ReminderType.birthday) {
      return ReminderTypeColors.bday500;
    }
    return SandPalette.sand600;
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

  IconData _typeBadgeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.chores:
        return Icons.cleaning_services_rounded;
      case ReminderType.appointment:
      case ReminderType.renewal:
      case ReminderType.vaccine:
        return Icons.event_available_rounded;
      case ReminderType.reimbursement:
        return Icons.receipt_long_rounded;
      case ReminderType.birthday:
        return Icons.card_giftcard_rounded;
      case ReminderType.custom:
        return Icons.sticky_note_2_rounded;
    }
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
        return '';
    }
  }

  String _buildDescription(
    String repeatLabel,
    String? timeLabel,
    AppLocalizations l,
  ) {
    final parts = <String>[];
    if (repeatLabel.isNotEmpty) {
      parts.add(repeatLabel);
    }
    if (timeLabel != null && timeLabel.isNotEmpty) {
      parts.add(timeLabel);
    }
    return parts.join(' · ');
  }
}

class _TypeColors {
  const _TypeColors({
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.badgeColor,
    required this.chipBgColor,
    required this.chipTextColor,
  });
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final Color badgeColor;
  final Color chipBgColor;
  final Color chipTextColor;
}

class _IconContainer extends StatelessWidget {
  const _IconContainer({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.badgeIcon,
    required this.badgeColor,
  });
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final IconData badgeIcon;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Center(child: Icon(icon, size: 28, color: iconColor)),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Icon(badgeIcon, size: 10, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssigneeRow extends StatelessWidget {
  const _AssigneeRow({required this.assigneeName, required this.assigneeColor});
  final String assigneeName;
  final Color assigneeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: SandPalette.sand200,
          child: Text(
            assigneeName.isNotEmpty ? assigneeName[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: SandPalette.sand600,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          assigneeName,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: assigneeColor,
          ),
        ),
      ],
    );
  }
}

class _TrailingSection extends StatelessWidget {
  const _TrailingSection({
    required this.timeLabel,
    required this.allDayLabel,
    required this.noDateLabel,
    required this.hasDueDate,
    required this.typeColors,
    required this.onMenuPressed,
  });
  final String? timeLabel;
  final String allDayLabel;
  final String noDateLabel;
  final bool hasDueDate;
  final _TypeColors typeColors;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final displayTime = timeLabel ?? (hasDueDate ? allDayLabel : noDateLabel);
    final isAllDay = timeLabel == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isAllDay ? typeColors.chipBgColor : typeColors.chipBgColor,
            border: Border.all(
              color: isAllDay ? typeColors.borderColor : typeColors.borderColor,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            displayTime,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: typeColors.chipTextColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onMenuPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SandPalette.sand100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.more_horiz_rounded,
                  size: 18,
                  color: SandPalette.sand400,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReminderMenuSheet extends StatelessWidget {
  const _ReminderMenuSheet({
    required this.reminder,
    required this.cubit,
    required this.onEdit,
    required this.onRemove,
  });
  final ReminderEntity reminder;
  final RemindersCubit cubit;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: SandPalette.sand50,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              decoration: BoxDecoration(
                color: SandPalette.sand300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                reminder.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: SandPalette.sand700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            _MenuItem(
              icon: Icons.edit_rounded,
              label: l.createReminderTitleEdit,
              onTap: onEdit,
            ),
            _MenuItem(
              icon: Icons.delete_rounded,
              label: l.reminderDeleteDialogConfirm,
              isDestructive: true,
              onTap: onRemove,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFD46D8B) : SandPalette.sand700;
    final bgColor = isDestructive
        ? const Color(0xFFFCE4EC)
        : SandPalette.sand100;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Icon(icon, size: 20, color: color)),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
