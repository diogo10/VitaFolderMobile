import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';
import 'package:vita_folder_mobile/theme/sand_palette.dart';

class SandBrandMark extends StatelessWidget {
  const SandBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: SandPalette.sand500,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.home_rounded,
            size: 18,
            color: SandPalette.sand50,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          AppLocalizations.of(context)!.appBrandName,
          style: const TextStyle(
            color: SandPalette.sand600,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
