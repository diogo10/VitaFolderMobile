import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:house_mira/features/people/presentation/widgets/family_header_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';

class HomeSuccessHeaderWidget extends StatelessWidget {
  final String role;
  final String familyName;
  final int activeMembers;
  final int pendingReminders;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onProfilePressed;

  const HomeSuccessHeaderWidget({
    super.key,
    required this.role,
    required this.familyName,
    required this.activeMembers,
    required this.pendingReminders,
    this.onNotificationsPressed,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FamilyHeaderWidget(
          role: role,
          onNotificationsPressed: onNotificationsPressed,
          onProfilePressed: onProfilePressed,
        ),
        const SizedBox(height: 22),
        Text(
          DateFormat('EEEE, MMMM d', l.localeName).format(DateTime.now()),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFFB0906C),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _greeting(l),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF604B38),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (familyName.isNotEmpty)
          Text(
            familyName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: const Color(0xFF604B38),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        const SizedBox(height: 10),
        Text(
          l.homeSuccessActiveMembers(activeMembers, pendingReminders),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _greeting(AppLocalizations l) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l.homeSuccessGreetingMorning;
    if (hour < 18) return l.homeSuccessGreetingAfternoon;
    return l.homeSuccessGreetingEvening;
  }
}
