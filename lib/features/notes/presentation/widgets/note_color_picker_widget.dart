import 'package:flutter/material.dart';
import 'package:house_mira/features/notes/domain/entities/note_color.dart';
import 'package:house_mira/features/notes/presentation/utils/note_color_palette.dart';
import 'package:house_mira/theme/sand_palette.dart';

/// Color swatch picker per `designs/html/01-FamilyAdmin - Notes (Create).html`:
/// exactly the 5 allowlisted swatches as large rounded tiles; the selected
/// tile gets a sand-500 border + soft ring.
class NoteColorPickerWidget extends StatelessWidget {
  const NoteColorPickerWidget({
    required this.selected,
    required this.onSelected,
    super.key,
  });
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final name in noteColorAllowlist)
          _Swatch(
            name: name,
            selected: name == selected,
            onTap: () => onSelected(name),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.name,
    required this.selected,
    required this.onTap,
  });
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderWidth = selected ? 2.0 : 1.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: noteColorPalette[name] ?? SandPalette.sand200,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? SandPalette.sand500
                : noteColorTilePalette[name] ?? SandPalette.sand200,
            width: borderWidth,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: SandPalette.sand500.withValues(alpha: 0.18),
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
