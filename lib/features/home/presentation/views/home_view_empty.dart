import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_action_card_widget.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_footer_widget.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_header_widget.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_invite_card_widget.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_reminders_widget.dart';

class HomeViewEmpty extends StatelessWidget {
  const HomeViewEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeEmptyHeaderWidget(),
            const SizedBox(height: 24),
            HomeEmptyActionCardWidget(
              icon: Icons.group_rounded,
              title: 'Add people to your Circle',
              subtitle: 'Invite parents, kids or caregivers to your family.',
              buttonLabel: 'Add',
              onPressed: () {},
            ),
            const SizedBox(height: 16),
            HomeEmptyActionCardWidget(
              icon: Icons.notifications_active_rounded,
              title: 'Set up a Reminder',
              subtitle: 'Schedule tasks, events and never miss a thing.',
              buttonLabel: 'Set up',
              onPressed: () {},
            ),
            const SizedBox(height: 16),
            HomeEmptyActionCardWidget(
              icon: Icons.person_add_alt_1_rounded,
              title: 'Complete your Account',
              subtitle: 'Add your name, photo and contact details.',
              buttonLabel: 'Go',
              onPressed: () {},
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
