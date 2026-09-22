import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/router/app_routes.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_state.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_view_mode.dart';
import 'package:house_mira/features/reminders/presentation/widgets/filter_bottom_sheet.dart';
import 'package:house_mira/features/reminders/presentation/widgets/filter_chips_widget.dart';
import 'package:house_mira/features/reminders/presentation/widgets/reminders_calendar_widget.dart';
import 'package:house_mira/features/reminders/presentation/widgets/reminders_empty_widget.dart';
import 'package:house_mira/features/reminders/presentation/widgets/reminders_error_widget.dart';
import 'package:house_mira/features/reminders/presentation/widgets/reminders_header_widget.dart';
import 'package:house_mira/features/reminders/presentation/widgets/reminders_loaded_widget.dart';
import 'package:house_mira/features/reminders/presentation/widgets/reminders_loading_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';

class RemindersView extends StatefulWidget {
  const RemindersView({super.key});

  @override
  State<RemindersView> createState() => _RemindersViewState();
}

class _RemindersViewState extends State<RemindersView> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<RemindersCubit>();
    if (cubit.authService.isLoggedIn()) {
      unawaited(cubit.getReminders());
    }
  }

  Future<void> _handleAddPressed() async {
    final cubit = context.read<RemindersCubit>();
    if (!cubit.authService.isLoggedIn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.needToBeLoggedIn)),
      );
      return;
    }
    final hasFamily = await cubit.hasFamily();
    if (!mounted) return;
    if (!hasFamily) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.createReminderErrorNoFamily,
          ),
        ),
      );
      context.go(AppRoutes.people);
      return;
    }
    await const CreateReminderRoute.create().push(context);
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
            final hasActiveFilters = state.filterTypes.isNotEmpty;
            final filteredReminders = _getFilteredReminders(state, cubit);

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
                      onNotificationsPressed: () =>
                          context.go(AppRoutes.account),
                      onProfilePressed: () => context.go(AppRoutes.account),
                      onAddPressed: _handleAddPressed,
                      onFilterPressed: () => _showFilterSheet(context),
                      hasActiveFilters: hasActiveFilters,
                    ),
                  ),
                  if (state.viewMode == RemindersViewMode.list) ...[
                    SliverToBoxAdapter(
                      child: FilterChipsWidget(
                        selectedType: cubit.selectedType,
                        onFilterChanged: (type) =>
                            cubit.getReminders(type: type),
                      ),
                    ),
                  ],
                  ..._contentSlivers(context, state, filteredReminders, cubit),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<ReminderEntity> _getFilteredReminders(
    RemindersState state,
    RemindersCubit cubit,
  ) {
    if (state is LoadedReminders) {
      return cubit.getFilteredReminders(state.reminders);
    }
    return const [];
  }

  void _showFilterSheet(BuildContext context) {
    final cubit = context.read<RemindersCubit>();
    final state = cubit.state;

    final typeCounts = <ReminderType, int>{};
    if (state is LoadedReminders) {
      for (final reminder in state.reminders) {
        typeCounts[reminder.type] = (typeCounts[reminder.type] ?? 0) + 1;
      }
    }

    showFilterBottomSheet(
      context: context,
      selectedTypes: state.filterTypes,
      typeCounts: typeCounts,
      onApply: cubit.setFilterTypes,
    );
  }

  List<Widget> _contentSlivers(
    BuildContext context,
    RemindersState state,
    List<ReminderEntity> filteredReminders,
    RemindersCubit cubit,
  ) {
    if (!cubit.authService.isLoggedIn()) {
      return const [SliverToBoxAdapter(child: RemindersEmptyWidget())];
    }
    if (state.viewMode == RemindersViewMode.calendar) {
      return switch (state) {
        LoadedReminders(:final reminders, :final isLoading) => [
          if (isLoading)
            const SliverToBoxAdapter(child: LinearProgressIndicator()),
          SliverToBoxAdapter(
            child: RemindersCalendarWidget(
              reminders: cubit.getFilteredReminders(reminders),
            ),
          ),
        ],
        EmptyReminders() => const [
          SliverToBoxAdapter(child: RemindersCalendarWidget(reminders: [])),
        ],
        _ => _listContentSlivers(context, state, filteredReminders, cubit),
      };
    }
    return _listContentSlivers(context, state, filteredReminders, cubit);
  }

  List<Widget> _listContentSlivers(
    BuildContext context,
    RemindersState state,
    List<ReminderEntity> filteredReminders,
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
      LoadedReminders(:final isLoading) => [
        if (isLoading)
          const SliverToBoxAdapter(child: LinearProgressIndicator()),
        if (filteredReminders.isEmpty)
          const SliverToBoxAdapter(child: RemindersEmptyWidget())
        else
          RemindersLoadedWidget(reminders: filteredReminders),
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
