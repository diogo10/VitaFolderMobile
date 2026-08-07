import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_state.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_action_card_widget.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_footer_widget.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_header_widget.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_invite_card_widget.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_reminders_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class HomeViewEmpty extends StatelessWidget {
  final HomeEmpty state;

  const HomeViewEmpty({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeEmptyHeaderWidget( 
              isLoggedIn: false,
            ),
            const SizedBox(height: 24),
            HomeEmptyActionCardWidget(
              icon: Icons.group_rounded,
              title: l.homeEmptyAddPeopleTitle,
              subtitle: l.homeEmptyAddPeopleSubtitle,
              buttonLabel: l.homeEmptyAddPeopleButton,
              onPressed: () => context.go('/people'),
            ),
            if (!state.hasReminders) ...[
              const SizedBox(height: 16),
              HomeEmptyActionCardWidget(
                icon: Icons.notifications_active_rounded,
                title: l.homeEmptyReminderTitle,
                subtitle: l.homeEmptyReminderSubtitle,
                buttonLabel: l.homeEmptyReminderButton,
                onPressed: () => context.go('/reminders'),
              ),
              const SizedBox(height: 16),
            ],
            HomeEmptyActionCardWidget(
              icon: Icons.person_add_alt_1_rounded,
              title: l.homeEmptyAccountTitle,
              subtitle: l.homeEmptyAccountSubtitle,
              buttonLabel: l.homeEmptyAccountButton,
              onPressed: () => context.go('/account'),
            ),
            const SizedBox(height: 20),
            HomeEmptyInviteCardWidget(
              onSharePressed: () {},
            ),
            const SizedBox(height: 24),
            const HomeEmptyFooterWidget(),
            const SizedBox(height: 20),
            const HomeEmptyRemindersWidget(),
          ],
        ),
      ),
    );
  }
}
