import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';
import 'package:vita_folder_mobile/theme/sand_palette.dart';

class FilterChipsWidget extends StatelessWidget {
  final ReminderType? selectedType;
  final ValueChanged<ReminderType?> onFilterChanged;

  const FilterChipsWidget({
    super.key,
    required this.selectedType,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final filters = [
      _FilterChipData(
        type: null,
        label: l.remindersHeaderAll,
        icon: null,
        bgColor: SandPalette.sand50,
        borderColor: SandPalette.sand200,
        textColor: SandPalette.sand700,
        activeBgColor: SandPalette.sand500,
        activeTextColor: SandPalette.sand50,
      ),
      _FilterChipData(
        type: ReminderType.chores,
        label: l.remindersFilterChores,
        icon: Icons.cleaning_services_rounded,
        bgColor: ReminderTypeColors.chores50,
        borderColor: ReminderTypeColors.chores100,
        textColor: ReminderTypeColors.chores600,
        activeBgColor: ReminderTypeColors.chores500,
        activeTextColor: Colors.white,
      ),
      _FilterChipData(
        type: ReminderType.appointment,
        label: l.remindersFilterAppointments,
        icon: Icons.event_available_rounded,
        bgColor: ReminderTypeColors.appts50,
        borderColor: ReminderTypeColors.appts100,
        textColor: ReminderTypeColors.appts600,
        activeBgColor: ReminderTypeColors.appts500,
        activeTextColor: Colors.white,
      ),
      _FilterChipData(
        type: ReminderType.birthday,
        label: l.remindersFilterBirthdays,
        icon: Icons.cake_rounded,
        bgColor: ReminderTypeColors.bday50,
        borderColor: ReminderTypeColors.bday100,
        textColor: ReminderTypeColors.bday600,
        activeBgColor: ReminderTypeColors.bday500,
        activeTextColor: Colors.white,
      ),
      _FilterChipData(
        type: ReminderType.renewal,
        label: l.remindersFilterRenewal,
        icon: Icons.autorenew_rounded,
        bgColor: ReminderTypeColors.renewal50,
        borderColor: ReminderTypeColors.renewal100,
        textColor: ReminderTypeColors.renewal600,
        activeBgColor: ReminderTypeColors.renewal500,
        activeTextColor: Colors.white,
      ),
      _FilterChipData(
        type: ReminderType.vaccine,
        label: l.remindersFilterVaccine,
        icon: Icons.vaccines_rounded,
        bgColor: ReminderTypeColors.vaccine50,
        borderColor: ReminderTypeColors.vaccine100,
        textColor: ReminderTypeColors.vaccine600,
        activeBgColor: ReminderTypeColors.vaccine500,
        activeTextColor: Colors.white,
      ),
      _FilterChipData(
        type: ReminderType.reimbursement,
        label: l.remindersFilterReimbursement,
        icon: Icons.receipt_long_rounded,
        bgColor: ReminderTypeColors.reimb50,
        borderColor: ReminderTypeColors.reimb100,
        textColor: ReminderTypeColors.reimb600,
        activeBgColor: ReminderTypeColors.reimb500,
        activeTextColor: Colors.white,
      ),
      _FilterChipData(
        type: ReminderType.custom,
        label: l.remindersFilterCustom,
        icon: Icons.sticky_note_2_rounded,
        bgColor: ReminderTypeColors.custom50,
        borderColor: ReminderTypeColors.custom100,
        textColor: ReminderTypeColors.custom600,
        activeBgColor: ReminderTypeColors.custom500,
        activeTextColor: Colors.white,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (int i = 0; i < filters.length; i++) ...[
            _FilterChip(
              data: filters[i],
              isSelected: filters[i].type == selectedType,
              onTap: () => onFilterChanged(filters[i].type),
            ),
            if (i < filters.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChipData {
  final ReminderType? type;
  final String label;
  final IconData? icon;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final Color activeBgColor;
  final Color activeTextColor;

  const _FilterChipData({
    required this.type,
    required this.label,
    this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.activeBgColor,
    required this.activeTextColor,
  });
}

class _FilterChip extends StatelessWidget {
  final _FilterChipData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? data.activeBgColor : data.bgColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? data.activeBgColor : data.borderColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data.icon != null) ...[
                  Icon(
                    data.icon,
                    size: 12,
                    color: isSelected ? data.activeTextColor : data.textColor,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? data.activeTextColor : data.textColor,
                    fontFamily: 'Figtree',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
