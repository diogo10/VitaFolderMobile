import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/features/people/presentation/widgets/family_header_widget.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_view_mode.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';
import 'package:vita_folder_mobile/theme/theme_extensions.dart';

class RemindersHeaderWidget extends StatefulWidget {
  final String title;
  final String? role;
  final ReminderType? selectedType;
  final RemindersViewMode? viewMode;
  final ValueChanged<ReminderType?>? onCategoryChanged;
  final VoidCallback? onAddPressed;
  final VoidCallback? onCalendarPressed;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onProfilePressed;

  const RemindersHeaderWidget({
    super.key,
    required this.title,
    this.role,
    this.selectedType,
    this.viewMode,
    this.onCategoryChanged,
    this.onAddPressed,
    this.onCalendarPressed,
    this.onNotificationsPressed,
    this.onProfilePressed,
  });

  @override
  State<RemindersHeaderWidget> createState() => _RemindersHeaderWidgetState();
}

class _RemindersHeaderWidgetState extends State<RemindersHeaderWidget> {
  List<({String label, ReminderType? type})> _categories(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return [
      (label: l.remindersHeaderAll, type: null),
      for (final type in ReminderType.values)
        (label: _typeLabel(type, l), type: type),
    ];
  }

  String _typeLabel(ReminderType type, AppLocalizations l) {
    switch (type) {
      case ReminderType.renewal:
        return l.createReminderTypeRenewal;
      case ReminderType.appointment:
        return l.createReminderTypeAppointment;
      case ReminderType.vaccine:
        return l.createReminderTypeVaccine;
      case ReminderType.reimbursement:
        return l.createReminderTypeReimbursement;
      case ReminderType.birthday:
        return l.createReminderTypeBirthday;
      case ReminderType.chores:
        return l.createReminderTypeChores;
      case ReminderType.custom:
        return l.createReminderTypeCustom;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories(context);
    final l = AppLocalizations.of(context)!;
    final textColor = context.colorScheme.onSurface;
    final background = context.colorScheme.surface;
    final highlight = context.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FamilyHeaderWidget(
                  role: widget.role,
                  onNotificationsPressed: widget.onNotificationsPressed,
                  onProfilePressed: widget.onProfilePressed,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: const Color(0xFF604B38),
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        onPressed: widget.onCalendarPressed,
                        tooltip: widget.viewMode == RemindersViewMode.calendar
                            ? l.remindersCalendarViewList
                            : l.remindersCalendarViewCalendar,
                        icon: Icon(
                          widget.viewMode == RemindersViewMode.calendar
                              ? Icons.view_list_rounded
                              : Icons.calendar_month_rounded,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        onPressed: widget.onAddPressed,
                        icon: Icon(Icons.add, color: textColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 62,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category.type == widget.selectedType;

                return ChoiceChip(
                  label: Text(category.label),
                  selected: isSelected,
                  onSelected: (_) {
                    widget.onCategoryChanged?.call(category.type);
                  },
                  selectedColor: highlight,
                  backgroundColor: background,
                  disabledColor: background,
                  labelStyle: context.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : textColor.withValues(alpha: 0.8),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? highlight
                        : textColor.withValues(alpha: 0.08),
                  ),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemCount: categories.length,
            ),
          ),
        ],
      ),
    );
  }
}
