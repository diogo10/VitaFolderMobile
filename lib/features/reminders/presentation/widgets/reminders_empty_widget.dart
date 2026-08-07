import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';
import 'package:vita_folder_mobile/theme/theme_extensions.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminders_suggestions_cards_widget.dart';

class RemindersEmptyWidget extends StatelessWidget {
  final bool isLoading;

  const RemindersEmptyWidget({
    super.key,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.colorScheme.primary;
    final onSurface = context.colorScheme.onSurface;
    final l = AppLocalizations.of(context)!;

    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: onSurface.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.notifications_rounded,
                      size: 32,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    l.remindersEmptyTitle,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.remindersEmptyDescription,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/create-reminder'),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(l.remindersEmptyCreateButton),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 8.0),
                  child: Text(
                    l.remindersEmptySuggestionsTitle,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: RemindersSuggestionsCardsWidget(),
            ),
          ],
        ),
      ),
        ),
        if (isLoading)
          const Positioned(
            top: 0,
            left: 24,
            right: 24,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}
