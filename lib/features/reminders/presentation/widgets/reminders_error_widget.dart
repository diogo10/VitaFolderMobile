import 'package:flutter/material.dart';
import 'package:house_mira/generated/app_localizations.dart';

class RemindersErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const RemindersErrorWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            l.remindersErrorTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.remindersErrorDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l.remindersErrorRetry),
            ),
          ],
        ],
      ),
    );
  }
}
