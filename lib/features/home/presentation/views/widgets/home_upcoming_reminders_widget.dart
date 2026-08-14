import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_reminder_tile_widget.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class HomeUpcomingRemindersWidget extends StatelessWidget {
  final List<ReminderEntity> reminders;
  final VoidCallback? onAddPressed;

  const HomeUpcomingRemindersWidget({
    super.key,
    required this.reminders,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final groups = _groupByDay(l);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.homeEmptyRemindersSectionTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: onAddPressed,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l.homeSuccessRemindersAdd),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final group in groups) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              group.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < group.reminders.length; i++) ...[
            HomeReminderTileWidget(reminder: group.reminders[i]),
            if (i != group.reminders.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  List<_ReminderGroup> _groupByDay(AppLocalizations l) {
    final now = DateTime.now();
    final today = DateFormat('dd/MM/yyyy').format(now);
    final tomorrow = DateFormat(
      'dd/MM/yyyy',
    ).format(now.add(const Duration(days: 1)));

    final todayList = <ReminderEntity>[];
    final tomorrowList = <ReminderEntity>[];
    final laterList = <ReminderEntity>[];

    for (final reminder in reminders) {
      final date = DateFormat('dd/MM/yyyy').tryParse(reminder.dueDate);
      if (date == null) {
        laterList.add(reminder);
      } else {
        final formatted = DateFormat('dd/MM/yyyy').format(date);
        if (formatted == today) {
          todayList.add(reminder);
        } else if (formatted == tomorrow) {
          tomorrowList.add(reminder);
        } else {
          laterList.add(reminder);
        }
      }
    }

    return [
      if (todayList.isNotEmpty)
        _ReminderGroup(
          label: l.homeSuccessRemindersToday,
          reminders: todayList,
        ),
      if (tomorrowList.isNotEmpty)
        _ReminderGroup(
          label: l.homeSuccessRemindersTomorrow,
          reminders: tomorrowList,
        ),
      if (laterList.isNotEmpty)
        _ReminderGroup(
          label: l.homeEmptyRemindersSectionTitle,
          reminders: laterList,
        ),
    ];
  }
}

class _ReminderGroup {
  final String label;
  final List<ReminderEntity> reminders;

  const _ReminderGroup({required this.label, required this.reminders});
}
