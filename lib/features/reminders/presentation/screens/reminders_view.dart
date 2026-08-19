import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_state.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_view_mode.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminders_calendar_widget.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminders_empty_widget.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminders_error_widget.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminders_header_widget.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminders_loaded_widget.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminders_loading_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class RemindersView extends StatefulWidget {
  const RemindersView({super.key});

  @override
  State<RemindersView> createState() => _RemindersViewState();
}

class _RemindersViewState extends State<RemindersView> {
  @override
  void initState() {
    super.initState();
    context.read<RemindersCubit>().getReminders();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<RemindersCubit>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      body: SafeArea(
        child: BlocBuilder<RemindersCubit, RemindersState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () => cubit.getReminders(type: cubit.selectedType),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: RemindersHeaderWidget(
                      title: l.remindersHeaderTitle,
                      role: cubit.myRole,
                      selectedType: cubit.selectedType,
                      viewMode: state.viewMode,
                      onCategoryChanged: (type) =>
                          cubit.getReminders(type: type),
                      onCalendarPressed: cubit.toggleViewMode,
                      onNotificationsPressed: () => context.go('/account'),
                      onProfilePressed: () => context.go('/account'),
                      onAddPressed: () => context.push('/create-reminder'),
                    ),
                  ),
                  ..._contentSlivers(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _contentSlivers(BuildContext context, RemindersState state) {
    final cubit = context.read<RemindersCubit>();
    if (state.viewMode == RemindersViewMode.calendar) {
      return switch (state) {
        LoadedReminders(:final reminders, :final isLoading) => [
          if (isLoading)
            const SliverToBoxAdapter(child: LinearProgressIndicator()),
          SliverToBoxAdapter(
            child: RemindersCalendarWidget(reminders: reminders),
          ),
        ],
        EmptyReminders() => const [
          SliverToBoxAdapter(child: RemindersCalendarWidget(reminders: [])),
        ],
        _ => _listContentSlivers(context, state, cubit),
      };
    }
    return _listContentSlivers(context, state, cubit);
  }

  List<Widget> _listContentSlivers(
    BuildContext context,
    RemindersState state,
    RemindersCubit cubit,
  ) {
    return switch (state) {
      RemindersLoading() => const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: RemindersLoadingWidget(),
        ),
      ],
      EmptyReminders(:final isLoading) => [
        SliverToBoxAdapter(child: RemindersEmptyWidget(isLoading: isLoading)),
      ],
      ReminderError() => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: RemindersErrorWidget(onRetry: () => cubit.getReminders()),
        ),
      ],
      LoadedReminders(:final reminders, :final isLoading) => [
        if (isLoading)
          const SliverToBoxAdapter(child: LinearProgressIndicator()),
        RemindersLoadedWidget(reminders: reminders),
      ],
      _ => const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: RemindersLoadingWidget(),
        ),
      ],
    };
  }
}
