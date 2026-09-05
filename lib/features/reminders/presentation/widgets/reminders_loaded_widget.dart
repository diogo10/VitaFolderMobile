import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/presentation/widgets/reminder_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/sand_palette.dart';

class RemindersLoadedWidget extends StatelessWidget {
  final List<ReminderEntity> reminders;

  const RemindersLoadedWidget({super.key, required this.reminders});

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDay(context);

    return SliverPadding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == groups.length) {
            return const _EndNoteWidget();
          }
          final item = groups[index];
          if (item.isHeader) {
            return _DayHeader(
              label: item.label,
              type: item.headerType!,
              date: item.headerDate!,
            );
          }
          return ReminderWidget(
            key: Key(item.reminder!.id),
            reminder: item.reminder!,
            isFutureDay: item.isFutureDay,
          );
        }, childCount: groups.length + 1), // +1 for end note
      ),
    );
  }

  List<_ListEntry> _groupByDay(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final todayKey = DateFormat('dd/MM/yyyy').format(now);
    final tomorrowKey = DateFormat(
      'dd/MM/yyyy',
    ).format(now.add(const Duration(days: 1)));

    final todayList = <ReminderEntity>[];
    final tomorrowList = <ReminderEntity>[];
    final laterMap = <String, List<ReminderEntity>>{};

    for (final reminder in reminders) {
      final date = DateFormat('dd/MM/yyyy').tryParse(reminder.dueDate);
      if (date == null) {
        laterMap.putIfAbsent('', () => []).add(reminder);
        continue;
      }
      final key = DateFormat('dd/MM/yyyy').format(date);
      if (key == todayKey) {
        todayList.add(reminder);
      } else if (key == tomorrowKey) {
        tomorrowList.add(reminder);
      } else {
        laterMap.putIfAbsent(key, () => []).add(reminder);
      }
    }

    final entries = <_ListEntry>[];

    if (todayList.isNotEmpty) {
      entries.add(
        _ListEntry.header(
          l.remindersLoadedSectionToday,
          DateFormat('MMM d').format(now),
          _HeaderType.today,
          now,
        ),
      );
      entries.addAll(todayList.map((r) => _ListEntry.reminder(r, false)));
    }

    if (tomorrowList.isNotEmpty) {
      final tomorrowDate = now.add(const Duration(days: 1));
      entries.add(
        _ListEntry.header(
          l.remindersLoadedSectionTomorrow,
          DateFormat('MMM d').format(tomorrowDate),
          _HeaderType.tomorrow,
          tomorrowDate,
        ),
      );
      entries.addAll(tomorrowList.map((r) => _ListEntry.reminder(r, false)));
    }

    final keys = laterMap.keys.toList()..sort();
    for (final key in keys) {
      final date = DateFormat('dd/MM/yyyy').tryParse(key);
      if (date != null) {
        final label =
            '${DateFormat('EEEE').format(date)} · ${DateFormat('MMM d').format(date)}';
        entries.add(
          _ListEntry.header(
            label,
            DateFormat('MMM d').format(date),
            _HeaderType.later,
            date,
          ),
        );
        entries.addAll(laterMap[key]!.map((r) => _ListEntry.reminder(r, true)));
      }
    }

    return entries;
  }
}

enum _HeaderType { today, tomorrow, later }

class _ListEntry {
  final String label;
  final ReminderEntity? reminder;
  final _HeaderType? headerType;
  final DateTime? headerDate;
  final bool isFutureDay;

  const _ListEntry._(
    this.label,
    this.reminder,
    this.headerType,
    this.headerDate,
    this.isFutureDay,
  );

  bool get isHeader => reminder == null;

  factory _ListEntry.header(
    String label,
    String dateLabel,
    _HeaderType type,
    DateTime date,
  ) => _ListEntry._(label, null, type, date, false);

  factory _ListEntry.reminder(ReminderEntity reminder, bool isFutureDay) =>
      _ListEntry._('', reminder, null, null, isFutureDay);
}

class _DayHeader extends StatelessWidget {
  final String label;
  final _HeaderType type;
  final DateTime date;

  const _DayHeader({
    required this.label,
    required this.type,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, bgColor, textColor, borderColor) = switch (type) {
      _HeaderType.today => (
        Icons.circle_rounded,
        SandPalette.sand500,
        SandPalette.sand50,
        SandPalette.sand200,
      ),
      _HeaderType.tomorrow => (
        Icons.access_time_rounded,
        SandPalette.sand100,
        SandPalette.sand500,
        SandPalette.sand200,
      ),
      _HeaderType.later => (
        Icons.calendar_month_rounded,
        SandPalette.sand100,
        SandPalette.sand500,
        SandPalette.sand200,
      ),
    };

    final dateLabel = DateFormat('MMM d').format(date);
    final fullLabel = '$label · $dateLabel';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: borderColor)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 10, color: textColor),
                const SizedBox(width: 6),
                Text(
                  fullLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: borderColor)),
        ],
      ),
    );
  }
}

class _EndNoteWidget extends StatelessWidget {
  const _EndNoteWidget();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          const Expanded(
            child: ColoredBox(
              color: SandPalette.sand200,
              child: SizedBox(height: 1),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            l.remindersAllCaughtUp,
            style: const TextStyle(fontSize: 11, color: SandPalette.sand300),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: ColoredBox(
              color: SandPalette.sand200,
              child: SizedBox(height: 1),
            ),
          ),
        ],
      ),
    );
  }
}
