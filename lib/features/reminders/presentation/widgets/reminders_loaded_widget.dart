import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminder_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class RemindersLoadedWidget extends StatelessWidget {
  final List<ReminderEntity> reminders;
  final ReminderType? selectedType;
  final bool isLoading;

  const RemindersLoadedWidget({
    super.key,
    required this.reminders,
    this.selectedType,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RemindersCubit>();
    final groups = _groupByDay(context);

    return RefreshIndicator(
      onRefresh: () => cubit.getReminders(type: selectedType),
      child: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _itemCount(groups),
            itemBuilder: (context, index) {
              final item = groups[index];
              if (item.isHeader) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFB0906C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }
              return ReminderWidget(
                key: Key(item.reminder!.id),
                reminder: item.reminder!,
              );
            },
          ),
          if (isLoading)
            const Positioned(
              top: 0,
              left: 24,
              right: 24,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  int _itemCount(List<_ListEntry> groups) => groups.length;

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
      entries
        ..add(
          _ListEntry.header(
            '${l.remindersLoadedSectionToday} · ${DateFormat('MMM d').format(now)}',
          ),
        )
        ..addAll(todayList.map(_ListEntry.reminder));
    }

    if (tomorrowList.isNotEmpty) {
      final tomorrowDate = now.add(const Duration(days: 1));
      entries
        ..add(
          _ListEntry.header(
            '${l.remindersLoadedSectionTomorrow} · ${DateFormat('MMM d').format(tomorrowDate)}',
          ),
        )
        ..addAll(tomorrowList.map(_ListEntry.reminder));
    }

    final keys = laterMap.keys.toList()..sort();
    for (final key in keys) {
      final date = DateFormat('dd/MM/yyyy').tryParse(key);
      final label = date == null
          ? ''
          : '${DateFormat('EEEE').format(date)} · ${DateFormat('MMM d').format(date)}';
      if (label.isNotEmpty) {
        entries.add(_ListEntry.header(label));
      }
      entries.addAll(laterMap[key]!.map(_ListEntry.reminder));
    }

    return entries;
  }
}

class _ListEntry {
  final String label;
  final ReminderEntity? reminder;

  const _ListEntry._(this.label, this.reminder);

  bool get isHeader => reminder == null;

  factory _ListEntry.header(String label) => _ListEntry._(label, null);

  factory _ListEntry.reminder(ReminderEntity reminder) =>
      _ListEntry._('', reminder);
}
