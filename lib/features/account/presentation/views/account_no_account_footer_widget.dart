import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';
import 'package:vita_folder_mobile/theme/sand_palette.dart';

class AccountNoAccountFooterWidget extends StatelessWidget {
  const AccountNoAccountFooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _AccountNoAccountTrustItem(
            icon: Icons.shield_outlined,
            label: l.accountNoAccountSecurePrivate,
          ),
          const _AccountNoAccountDot(),
          _AccountNoAccountTrustItem(
            icon: Icons.star_rounded,
            label: l.accountNoAccountFreeToStart,
          ),
          const _AccountNoAccountDot(),
          _AccountNoAccountTrustItem(
            icon: Icons.groups_rounded,
            label: l.accountNoAccountFamilyPlan,
          ),
        ],
      ),
    );
  }
}

class _AccountNoAccountTrustItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AccountNoAccountTrustItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: SandPalette.sand400),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: SandPalette.sand400),
        ),
      ],
    );
  }
}

class _AccountNoAccountDot extends StatelessWidget {
  const _AccountNoAccountDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: SandPalette.sand300,
        shape: BoxShape.circle,
      ),
    );
  }
}
