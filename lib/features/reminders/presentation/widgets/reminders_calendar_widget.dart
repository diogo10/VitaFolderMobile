import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminder_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';
import 'package:vita_folder_mobile/theme/theme_extensions.dart';

class RemindersCalendarWidget extends StatefulWidget {
  final List<ReminderEntity> reminders;

  const RemindersCalendarWidget({super.key, required this.reminders});

  @override
  State<RemindersCalendarWidget> createState() =>
      _RemindersCalendarWidgetState();
}

class _RemindersCalendarWidgetState extends State<RemindersCalendarWidget> {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  late DateTime _visibleMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  DateTime? _selectedDate;

  DateTime? _tryParseDate(String dueDate) {
    final trimmed = dueDate.trim();
    if (trimmed.isEmpty) return null;
    return _dateFormat.tryParse(trimmed);
  }

  Set<String> get _reminderDayKeys => {
    for (final reminder in widget.reminders)
      if (_tryParseDate(reminder.dueDate) case final date?)
        _dateFormat.format(date),
  };

  List<ReminderEntity> get _selectedDayReminders {
    final selectedKey = _selectedDate == null
        ? null
        : _dateFormat.format(_selectedDate!);
    if (selectedKey == null) return const [];
    return widget.reminders.where((r) {
      final date = _tryParseDate(r.dueDate);
      return date != null && _dateFormat.format(date) == selectedKey;
    }).toList();
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _selectDay(DateTime date) {
    setState(() => _selectedDate = date);
  }

  @override
  Widget build(BuildContext context) {
    final highlight = context.colorScheme.primary;
    final textColor = context.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMonthHeader(context),
        const SizedBox(height: 12),
        _buildWeekdayHeader(context),
        const SizedBox(height: 4),
        _buildMonthGrid(context),
        if (_selectedDate != null) ...[
          const SizedBox(height: 16),
          _buildSelectedDaySection(context, highlight, textColor),
        ],
      ],
    );
  }

  Widget _buildMonthHeader(BuildContext context) {
    final textColor = context.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
          icon: const Icon(Icons.chevron_left_rounded),
          color: textColor,
        ),
        Text(
          DateFormat('MMMM yyyy').format(_visibleMonth),
          style: context.textTheme.titleMedium?.copyWith(
            color: const Color(0xFF604B38),
            fontWeight: FontWeight.w800,
          ),
        ),
        IconButton(
          onPressed: () => _changeMonth(1),
          tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
          icon: const Icon(Icons.chevron_right_rounded),
          color: textColor,
        ),
      ],
    ));
  }

  Widget _buildWeekdayHeader(BuildContext context) {
    final textColor = context.colorScheme.onSurfaceVariant;
    final firstDayOfWeek = MaterialLocalizations.of(
      context,
    ).firstDayOfWeekIndex;
    final names = <String>[
      for (var i = 0; i < 7; i++)
        DateFormat(
          'EEEEE',
        ).format(DateTime(2020, 1, (i + firstDayOfWeek) % 7 + 1)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          for (final name in names)
            Expanded(
              child: Center(
                child: Text(
                  name,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(BuildContext context) {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month);
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final firstDayOfWeek = MaterialLocalizations.of(
      context,
    ).firstDayOfWeekIndex;
    final offset = (firstDay.weekday % 7 - firstDayOfWeek + 7) % 7;
    final cells = offset + daysInMonth;
    final todayKey = _dateFormat.format(DateTime.now());
    final reminderKeys = _reminderDayKeys;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent: 48,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: cells,
      itemBuilder: (context, index) {
        if (index < offset) {
          return const SizedBox.shrink();
        }
        final day = index - offset + 1;
        final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
        final dateKey = _dateFormat.format(date);
        final isToday = dateKey == todayKey;
        final isSelected =
            _selectedDate != null && _sameDay(date, _selectedDate!);
        final hasReminders = reminderKeys.contains(dateKey);

        return _DayCell(
          day: day,
          isToday: isToday,
          isSelected: isSelected,
          hasReminders: hasReminders,
          onTap: () => _selectDay(date),
        );
      },
      ),
    );
  }

  Widget _buildSelectedDaySection(
    BuildContext context,
    Color highlight,
    Color textColor,
  ) {
    final l = AppLocalizations.of(context)!;
    final reminders = _selectedDayReminders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24.0),
          child: Text(
            DateFormat('EEEE, MMMM d').format(_selectedDate!),
            style: context.textTheme.labelLarge?.copyWith(
              color: const Color.fromARGB(255, 98, 90, 80),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (reminders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l.remindersCalendarEmptyDay,
              style: context.textTheme.bodyMedium?.copyWith(color: textColor),
            ),
          )
        else
          for (final reminder in reminders)
            ReminderWidget(key: Key(reminder.id), reminder: reminder),
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasReminders;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasReminders,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final highlight = colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? highlight : null,
          borderRadius: BorderRadius.circular(12),
          border: isToday ? Border.all(color: highlight, width: 1.5) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: context.textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : colorScheme.onSurface,
                fontWeight: isSelected || isToday
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: hasReminders
                    ? (isSelected ? Colors.white : highlight)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
