import 'package:flutter/material.dart';
import 'package:house_mira/features/people/presentation/widgets/family_header_widget.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_view_mode.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/sand_palette.dart';
import 'package:house_mira/theme/theme_extensions.dart';

class RemindersHeaderWidget extends StatefulWidget {

  const RemindersHeaderWidget({
    required this.title, super.key,
    this.role,
    this.selectedType,
    this.viewMode,
    this.onCategoryChanged,
    this.onAddPressed,
    this.onCalendarPressed,
    this.onNotificationsPressed,
    this.onProfilePressed,
    this.onFilterPressed,
    this.hasActiveFilters = false,
  });
  final String title;
  final String? role;
  final ReminderType? selectedType;
  final RemindersViewMode? viewMode;
  final ValueChanged<ReminderType?>? onCategoryChanged;
  final VoidCallback? onAddPressed;
  final VoidCallback? onCalendarPressed;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onFilterPressed;
  final bool hasActiveFilters;

  @override
  State<RemindersHeaderWidget> createState() => _RemindersHeaderWidgetState();
}

class _RemindersHeaderWidgetState extends State<RemindersHeaderWidget> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final textColor = context.colorScheme.onSurface;
    final background = context.colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
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
                              color: SandPalette.sand700,
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
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          IconButton(
                            onPressed: widget.onFilterPressed,
                            icon: Icon(Icons.tune_rounded, color: textColor),
                          ),
                          if (widget.hasActiveFilters)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: SandPalette.sand500,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: SandPalette.sand50,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
