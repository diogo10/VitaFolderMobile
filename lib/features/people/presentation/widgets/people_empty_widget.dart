import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class PeopleEmptyWidget extends StatelessWidget {
  const PeopleEmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people_outline_rounded,
            size: 72,
            color: Color(0xFFB0906C),
          ),
          const SizedBox(height: 16),
          Text(
            l.peopleEmptyTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF604B38),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.peopleEmptyDescription,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFB0906C),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
