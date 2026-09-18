import 'package:flutter/material.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/utils/reminder_date_utils.dart';
import 'package:house_mira/features/reminders/presentation/widgets/reminder_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/sand_palette.dart';
import 'package:intl/intl.dart';

class RemindersCalendarWidget extends StatefulWidget {
  const RemindersCalendarWidget({required this.reminders, super.key});
  final List<ReminderEntity> reminders;

  @override
  State<RemindersCalendarWidget> createState() =>
      _RemindersCalendarWidgetState();
}

class _RemindersCalendarWidgetState extends State<RemindersCalendarWidget> {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _monthFormat = DateFormat('MMMM yyyy');
  static final DateFormat _dayDetailFormat = DateFormat('EEEE, MMMM d');

  late DateTime _visibleMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  DateTime? _selectedDate;

  static bool _occursOnDate(ReminderEntity reminder, DateTime date) {
    return ReminderDateUtils.occursOnDate(reminder, date);
  }

  Set<String> get _reminderDayKeys {
    final keys = <String>{};
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
      for (final reminder in widget.reminders) {
        if (_occursOnDate(reminder, date)) {
          keys.add(_dateFormat.format(date));
          break;
        }
      }
    }
    return keys;
  }

  List<ReminderEntity> get _selectedDayReminders {
    if (_selectedDate == null) return const [];
    return widget.reminders.where((r) {
      return _occursOnDate(r, _selectedDate!);
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCalendarCard(context),
          if (_selectedDate != null) ...[
            const SizedBox(height: 16),
            _buildSelectedDaySection(context),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 382),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: SandPalette.sand100),
          boxShadow: [
            BoxShadow(
              color: SandPalette.sand500.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthHeader(context),
            const SizedBox(height: 16),
            _buildWeekdayHeader(context),
            const SizedBox(height: 8),
            _buildMonthGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
          icon: const Icon(Icons.chevron_left_rounded, size: 24),
          color: SandPalette.sand400,
          hoverColor: SandPalette.sand600.withValues(alpha: 0.1),
          splashRadius: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Flexible(
          child: Text(
            _monthFormat.format(_visibleMonth),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: SandPalette.sand700,
            ),
          ),
        ),
        IconButton(
          onPressed: () => _changeMonth(1),
          tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
          icon: const Icon(Icons.chevron_right_rounded, size: 24),
          color: SandPalette.sand400,
          hoverColor: SandPalette.sand600.withValues(alpha: 0.1),
          splashRadius: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader(BuildContext context) {
    final firstDayOfWeek = MaterialLocalizations.of(
      context,
    ).firstDayOfWeekIndex;
    // Jan 6, 2020 is a Monday. Use as base for Mon..Sun names.
    final baseNames = <String>[
      for (var i = 0; i < 7; i++)
        DateFormat('EEEEE').format(DateTime(2020, 1, 6 + i)),
    ];
    // Rotate to start with locale's first day of week
    final names = <String>[
      for (var i = 0; i < 7; i++) baseNames[(i + firstDayOfWeek) % 7],
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 4,
      ),
      itemCount: 7,
      itemBuilder: (context, index) {
        return Center(
          child: Text(
            names[index].toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: SandPalette.sand300,
            ),
          ),
        );
      },
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
    // Dart weekday: 1=Mon..7=Sun. Convert to 0=Mon..6=Sun,
    // then subtract firstDayOfWeekIndex (0=Mon..6=Sun)
    final offset = ((firstDay.weekday - 1 - firstDayOfWeek) % 7 + 7) % 7;
    final cells = offset + daysInMonth;
    final todayKey = _dateFormat.format(DateTime.now());
    final reminderKeys = _reminderDayKeys;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 4,
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
        const isCurrentMonth = true;

        return _DayCell(
          day: day,
          isToday: isToday,
          isSelected: isSelected,
          hasReminders: hasReminders,
          isCurrentMonth: isCurrentMonth,
          onTap: () => _selectDay(date),
        );
      },
    );
  }

  Widget _buildSelectedDaySection(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final reminders = _selectedDayReminders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  _dayDetailFormat.format(_selectedDate!),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SandPalette.sand600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '${reminders.length} ${l.homeTasks}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: SandPalette.sand400,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (reminders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.only(left: 18, right: 8),
              child: Text(
                l.remindersCalendarEmptyDay,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: SandPalette.sand400),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reminders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => ReminderWidget(
              key: Key(reminders[index].id),
              reminder: reminders[index],
            ),
          ),
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasReminders,
    required this.isCurrentMonth,
    required this.onTap,
  });
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasReminders;
  final bool isCurrentMonth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color? backgroundColor;
    const double borderRadius = 12;

    if (isSelected) {
      textColor = Colors.white;
      backgroundColor = SandPalette.sand500;
    } else if (isToday) {
      textColor = SandPalette.sand500;
      backgroundColor = Colors.transparent;
    } else if (isCurrentMonth) {
      textColor = SandPalette.sand700;
      backgroundColor = Colors.transparent;
    } else {
      textColor = SandPalette.sand300;
      backgroundColor = Colors.transparent;
    }

    final fontWeight = (isSelected || isToday)
        ? FontWeight.w800
        : FontWeight.w500;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: isToday && !isSelected
              ? Border.all(color: SandPalette.sand500, width: 1.5)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                '$day',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: fontWeight,
                  fontSize: 14,
                ),
              ),
            ),
            if (hasReminders && !isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: SandPalette.sand300,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            if (hasReminders && isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
