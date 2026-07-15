import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';
import 'package:vita_folder_mobile/theme/theme_extensions.dart';

class RemindersHeaderWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final ValueChanged<String>? onCategoryChanged;
  final VoidCallback? onFilterPressed;

  const RemindersHeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.onCategoryChanged,
    this.onFilterPressed,
  });

  @override
  State<RemindersHeaderWidget> createState() => _RemindersHeaderWidgetState();
}

class _RemindersHeaderWidgetState extends State<RemindersHeaderWidget> {
  String selectedCategory = '';

  List<String> _categories(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return [l.remindersHeaderAll, l.remindersHeaderChores, l.remindersHeaderAppointments, l.remindersHeaderBirthdays];
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories(context);
    if (selectedCategory.isEmpty) selectedCategory = categories.first;
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF604B38),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    onPressed: widget.onFilterPressed,
                    icon: Icon(
                      Icons.tune_rounded,
                      color: textColor,
                    ),
                  ),
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
                final isSelected = category == selectedCategory;
      
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      selectedCategory = category;
                    });
                    widget.onCategoryChanged?.call(category);
                  },
                  selectedColor: highlight,
                  backgroundColor: background,
                  disabledColor: background,
                  labelStyle: context.textTheme.bodyMedium?.copyWith(
                    color: isSelected ? Colors.white : textColor.withValues(alpha: 0.8),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  side: BorderSide(
                    color: isSelected ? highlight : textColor.withValues(alpha: 0.08),
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
