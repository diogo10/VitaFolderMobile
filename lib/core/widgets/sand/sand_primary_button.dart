import 'package:flutter/material.dart';
import 'package:house_mira/theme/sand_palette.dart';

class SandPrimaryButton extends StatelessWidget {

  const SandPrimaryButton({
    required this.label, required this.icon, super.key,
    this.isLoading = false,
    this.onPressed,
  });
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final showDimmed = isLoading || isDisabled;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isLoading
                ? SandPalette.sand500.withValues(alpha: 0.7)
                : isDisabled
                ? SandPalette.sand300
                : SandPalette.sand500,
            borderRadius: BorderRadius.circular(28),
            boxShadow: showDimmed
                ? null
                : [
                    BoxShadow(
                      color: SandPalette.sand500.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else ...[
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
