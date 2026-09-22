import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/router/app_routes.dart';
import 'package:house_mira/features/home/presentation/cubit/home_cubit.dart';
import 'package:house_mira/features/home/presentation/cubit/home_state.dart';
import 'package:house_mira/features/home/presentation/views/widgets/home_empty_action_card_widget.dart';
import 'package:house_mira/features/home/presentation/views/widgets/home_empty_footer_widget.dart';
import 'package:house_mira/features/home/presentation/views/widgets/home_empty_header_widget.dart';
import 'package:house_mira/features/home/presentation/views/widgets/home_empty_invite_card_widget.dart';
import 'package:house_mira/features/home/presentation/views/widgets/home_empty_reminders_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class HomeViewEmpty extends StatelessWidget {
  const HomeViewEmpty({required this.state, super.key});
  final HomeEmpty state;

  Future<void> _shareInvite(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    await Share.share(l.homeEmptyInviteShareMessage);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => context.read<HomeCubit>().getHomeData(isRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeEmptyHeaderWidget(),
              const SizedBox(height: 24),
              HomeEmptyActionCardWidget(
                icon: Icons.group_rounded,
                title: l.homeEmptyAddPeopleTitle,
                subtitle: l.homeEmptyAddPeopleSubtitle,
                buttonLabel: l.homeEmptyAddPeopleButton,
                onPressed: () => context.go(AppRoutes.people),
              ),
              if (!state.hasReminders) ...[
                const SizedBox(height: 16),
                HomeEmptyActionCardWidget(
                  icon: Icons.notifications_active_rounded,
                  title: l.homeEmptyReminderTitle,
                  subtitle: l.homeEmptyReminderSubtitle,
                  buttonLabel: l.homeEmptyReminderButton,
                  onPressed: () => context.go(AppRoutes.reminders),
                ),
                const SizedBox(height: 16),
              ],
              HomeEmptyActionCardWidget(
                icon: Icons.person_add_alt_1_rounded,
                title: l.homeEmptyAccountTitle,
                subtitle: l.homeEmptyAccountSubtitle,
                buttonLabel: l.homeEmptyAccountButton,
                onPressed: () => context.go(AppRoutes.account),
              ),
              const SizedBox(height: 20),
              HomeEmptyInviteCardWidget(
                onSharePressed: () => _shareInvite(context),
              ),
              const SizedBox(height: 24),
              const HomeEmptyFooterWidget(),
              const SizedBox(height: 20),
              const HomeEmptyRemindersWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
