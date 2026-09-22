import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/router/app_routes.dart';
import 'package:house_mira/features/home/domain/entities/home_entity.dart';
import 'package:house_mira/features/home/presentation/cubit/home_cubit.dart';
import 'package:house_mira/features/home/presentation/views/widgets/home_circle_widget.dart';
import 'package:house_mira/features/home/presentation/views/widgets/home_empty_action_card_widget.dart';
import 'package:house_mira/features/home/presentation/views/widgets/home_empty_footer_widget.dart';
import 'package:house_mira/features/home/presentation/views/widgets/home_empty_invite_card_widget.dart';
import 'package:house_mira/features/home/presentation/views/widgets/home_empty_reminders_widget.dart';
import 'package:house_mira/features/home/presentation/views/widgets/home_success_header_widget.dart';
import 'package:house_mira/features/home/presentation/views/widgets/home_upcoming_reminders_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class HomeViewSuccess extends StatelessWidget {
  const HomeViewSuccess({required this.data, super.key});
  final HomeEntity data;

  Future<void> _shareInvite(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    await Share.share(l.homeEmptyInviteShareMessage);
  }

  int get _pendingReminders => data.reminders
      .where((r) => r.status == 'pending' || r.status == 'sent')
      .length;

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
              HomeSuccessHeaderWidget(
                role: data.myRole,
                familyName: data.familyName,
                activeMembers: data.activeMembers,
                pendingReminders: _pendingReminders,
                onNotificationsPressed: () => context.go(AppRoutes.account),
                onProfilePressed: () => context.go(AppRoutes.account),
              ),
              const SizedBox(height: 24),
              if (data.peopleInCircle.isNotEmpty) ...[
                HomeEmptyInviteCardWidget(
                  onSharePressed: () => _shareInvite(context),
                ),
                const SizedBox(height: 24),
              ],
              if (data.peopleInCircle.isNotEmpty)
                HomeCircleWidget(
                  people: data.peopleInCircle,
                  onManagePressed: () => context.go(AppRoutes.people),
                )
              else
                const HomeEmptyFooterWidget(),
              const SizedBox(height: 24),
              HomeEmptyActionCardWidget(
                icon: Icons.task_alt_rounded,
                title: l.homeSuccessAddTaskTitle,
                subtitle: l.homeSuccessAddTaskSubtitle,
                buttonLabel: l.homeSuccessAddTaskButton,
                onPressed: () =>
                    const CreateReminderRoute.create().push(context),
              ),
              const SizedBox(height: 16),
              HomeEmptyActionCardWidget(
                icon: Icons.calendar_month_rounded,
                title: l.homeSuccessManageActivityTitle,
                subtitle: l.homeSuccessManageActivitySubtitle,
                buttonLabel: l.homeSuccessManageActivityButton,
                onPressed: () => context.go(AppRoutes.reminders),
              ),
              const SizedBox(height: 24),
              if (data.reminders.isEmpty)
                const HomeEmptyRemindersWidget()
              else
                HomeUpcomingRemindersWidget(
                  reminders: data.reminders,
                  onAddPressed: () =>
                      const CreateReminderRoute.create().push(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
