import 'package:flutter/material.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/sand_palette.dart';

class FilterBottomSheet extends StatefulWidget {
  final Set<ReminderType> selectedTypes;
  final Map<ReminderType, int> typeCounts;
  final ValueChanged<Set<ReminderType>> onApply;

  const FilterBottomSheet({
    super.key,
    required this.selectedTypes,
    required this.typeCounts,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Set<ReminderType> _selectedTypes;

  @override
  void initState() {
    super.initState();
    _selectedTypes = Set.from(widget.selectedTypes);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final filterOptions = [
      _FilterOption(
        type: ReminderType.chores,
        label: l.remindersFilterChores,
        icon: Icons.cleaning_services_rounded,
        iconBgColor: ReminderTypeColors.chores100,
        iconColor: ReminderTypeColors.chores500,
        countColor: ReminderTypeColors.chores500,
        countBgColor: ReminderTypeColors.chores100,
        count: widget.typeCounts[ReminderType.chores] ?? 0,
      ),
      _FilterOption(
        type: ReminderType.appointment,
        label: l.remindersFilterAppointments,
        icon: Icons.event_available_rounded,
        iconBgColor: ReminderTypeColors.appts50,
        iconColor: ReminderTypeColors.appts500,
        countColor: ReminderTypeColors.appts500,
        countBgColor: ReminderTypeColors.appts100,
        count: widget.typeCounts[ReminderType.appointment] ?? 0,
      ),
      _FilterOption(
        type: ReminderType.birthday,
        label: l.remindersFilterBirthdays,
        icon: Icons.cake_rounded,
        iconBgColor: ReminderTypeColors.bday50,
        iconColor: ReminderTypeColors.bday400,
        countColor: ReminderTypeColors.bday500,
        countBgColor: ReminderTypeColors.bday100,
        count: widget.typeCounts[ReminderType.birthday] ?? 0,
      ),
      _FilterOption(
        type: ReminderType.renewal,
        label: l.remindersFilterRenewal,
        icon: Icons.autorenew_rounded,
        iconBgColor: ReminderTypeColors.renewal50,
        iconColor: ReminderTypeColors.renewal500,
        countColor: ReminderTypeColors.renewal500,
        countBgColor: ReminderTypeColors.renewal100,
        count: widget.typeCounts[ReminderType.renewal] ?? 0,
      ),
      _FilterOption(
        type: ReminderType.vaccine,
        label: l.remindersFilterVaccine,
        icon: Icons.vaccines_rounded,
        iconBgColor: ReminderTypeColors.vaccine50,
        iconColor: ReminderTypeColors.vaccine500,
        countColor: ReminderTypeColors.vaccine500,
        countBgColor: ReminderTypeColors.vaccine100,
        count: widget.typeCounts[ReminderType.vaccine] ?? 0,
      ),
      _FilterOption(
        type: ReminderType.reimbursement,
        label: l.remindersFilterReimbursement,
        icon: Icons.receipt_long_rounded,
        iconBgColor: ReminderTypeColors.reimb50,
        iconColor: ReminderTypeColors.reimb500,
        countColor: ReminderTypeColors.reimb500,
        countBgColor: ReminderTypeColors.reimb100,
        count: widget.typeCounts[ReminderType.reimbursement] ?? 0,
      ),
      _FilterOption(
        type: ReminderType.custom,
        label: l.remindersFilterCustom,
        icon: Icons.sticky_note_2_rounded,
        iconBgColor: ReminderTypeColors.custom50,
        iconColor: ReminderTypeColors.custom500,
        countColor: ReminderTypeColors.custom500,
        countBgColor: ReminderTypeColors.custom100,
        count: widget.typeCounts[ReminderType.custom] ?? 0,
      ),
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
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
                l.remindersFilterTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: SandPalette.sand700,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (int i = 0; i < filterOptions.length; i++) ...[
                      _FilterCheckboxTile(
                        option: filterOptions[i],
                        isSelected: _selectedTypes.contains(
                          filterOptions[i].type,
                        ),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedTypes.add(filterOptions[i].type);
                            } else {
                              _selectedTypes.remove(filterOptions[i].type);
                            }
                          });
                        },
                      ),
                      if (i < filterOptions.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onApply(_selectedTypes),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SandPalette.sand500,
                    foregroundColor: SandPalette.sand50,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l.remindersFilterApply,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: SandPalette.sand50,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _FilterOption {
  final ReminderType type;
  final String label;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final Color countColor;
  final Color countBgColor;
  final int count;

  const _FilterOption({
    required this.type,
    required this.label,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.countColor,
    required this.countBgColor,
    required this.count,
  });
}

class _FilterCheckboxTile extends StatelessWidget {
  final _FilterOption option;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const _FilterCheckboxTile({
    required this.option,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!isSelected),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SandPalette.sand100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SandPalette.sand200, width: 1),
          ),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: onChanged,
                activeColor: option.iconColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: option.iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(option.icon, size: 20, color: option.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: SandPalette.sand700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: option.countBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${option.count}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: option.countColor,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterBottomSheetOverlay extends StatelessWidget {
  final bool isOpen;
  final Widget child;
  final VoidCallback onDismiss;

  const FilterBottomSheetOverlay({
    super.key,
    required this.isOpen,
    required this.child,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      bottom: isOpen ? 0 : -MediaQuery.of(context).size.height,
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          color: Colors.black.withValues(alpha: isOpen ? 0.3 : 0.0),
          child: child,
        ),
      ),
    );
  }
}

void showFilterBottomSheet({
  required BuildContext context,
  required Set<ReminderType> selectedTypes,
  required Map<ReminderType, int> typeCounts,
  required ValueChanged<Set<ReminderType>> onApply,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    builder: (context) => FilterBottomSheet(
      selectedTypes: selectedTypes,
      typeCounts: typeCounts,
      onApply: (types) {
        onApply(types);
        Navigator.of(context).pop();
      },
    ),
  );
}
