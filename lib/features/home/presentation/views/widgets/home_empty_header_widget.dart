import 'package:flutter/material.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/theme_extensions.dart';

class HomeEmptyHeaderWidget extends StatelessWidget {
  const HomeEmptyHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.homeEmptyHeaderTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF604B38),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l.homeEmptyHeaderDescription,
          style: context.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
