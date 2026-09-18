import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/theme/sand_palette.dart';

/// Shared navigation header matching `CreateReminderScreen._buildHeader`.
///
/// Pixels: 40x40 white back button (radius 16, [SandPalette.sand200] border,
/// `chevron_left_rounded` 24 in [SandPalette.sand600]), 16px gap, 20px bold
/// [SandPalette.sand700] title, trailing spacer (56px) for optical centering
/// unless a [trailing] action is provided.
class SandHeader extends StatelessWidget {

  const SandHeader({
    required this.title, super.key,
    this.trailing,
    this.onBack,
  });
  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: SandPalette.sand50,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onBack ?? () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SandPalette.sand200),
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: SandPalette.sand600,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: SandPalette.sand700,
              ),
            ),
          ),
          trailing ?? const SizedBox(width: 56),
        ],
      ),
    );
  }
}
