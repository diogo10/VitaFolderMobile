import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';
import 'package:vita_folder_mobile/theme/theme_extensions.dart';

class RemindersSuggestionsCardsWidget extends StatelessWidget {
  const RemindersSuggestionsCardsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        children: [
          _ReminderSuggestionCard(
            icon: Icons.cleaning_services_rounded,
            iconBackground: const Color(0xFFFAE4B5),
            iconColor: const Color(0xFFB68C3B),
            title: l.remindersSuggestionsChoresTitle,
            subtitle: l.remindersSuggestionsChoresSubtitle,
            buttonColor: const Color(0xFFB68C3B),
            buttonLabel: l.remindersSuggestionsAddButton,
            reminderType: ReminderType.chores,
          ),
          const SizedBox(height: 12),
          _ReminderSuggestionCard(
            icon: Icons.event_rounded,
            iconBackground: const Color(0xFFD8EBFF),
            iconColor: const Color(0xFF4076C3),
            title: l.remindersSuggestionsAppointmentsTitle,
            subtitle: l.remindersSuggestionsAppointmentsSubtitle,
            buttonColor: const Color(0xFF4076C3),
            buttonLabel: l.remindersSuggestionsAddButton,
            reminderType: ReminderType.appointment,
          ),
          const SizedBox(height: 12),
          _ReminderSuggestionCard(
            icon: Icons.cake_rounded,
            iconBackground: const Color(0xFFFCDDE6),
            iconColor: const Color(0xFFD46D8B),
            title: l.remindersSuggestionsBirthdaysTitle,
            subtitle: l.remindersSuggestionsBirthdaysSubtitle,
            buttonColor: const Color(0xFFD46D8B),
            buttonLabel: l.remindersSuggestionsAddButton,
            reminderType: ReminderType.birthday,
          ),
        ],
      ),
    );
  }
}

class _ReminderSuggestionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color buttonColor;
  final String buttonLabel;
  final ReminderType reminderType;

  const _ReminderSuggestionCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonColor,
    required this.buttonLabel,
    required this.reminderType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: buttonColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextButton(
              onPressed: () => context.push(
                '/create-reminder',
                extra: reminderType,
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                foregroundColor: buttonColor,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
