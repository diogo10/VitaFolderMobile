import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class PendingInviteCardWidget extends StatelessWidget {
  final String email;
  final String sentAtLabel;
  final VoidCallback? onResendPressed;

  const PendingInviteCardWidget({
    super.key,
    required this.email,
    required this.sentAtLabel,
    this.onResendPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    const orange = Color(0xFFE67E22);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5CF6A)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3C4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Colors.orange,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.peopleWidgetsPendingInviteCardTitle,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFAD4B0B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$email · sent $sentAtLabel',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: orange, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onResendPressed,
            style: TextButton.styleFrom(
              foregroundColor: orange,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l.peopleWidgetsPendingInviteResendButton,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
