import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_state.dart';
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
        child: Column(
          children: [
            BlocBuilder<RemindersCubit, RemindersState>(
              builder: (context, _) {
                return RemindersHeaderWidget(
                  title: l.remindersHeaderTitle,
                  subtitle: l.remindersHeaderSubtitle,
                  selectedType: cubit.selectedType,
                  onCategoryChanged: (type) => cubit.getReminders(type: type),
                );
              },
            ),
            Expanded(
              child: BlocBuilder<RemindersCubit, RemindersState>(
                builder: (context, state) {
                  return switch (state) {
                    RemindersLoading() => const RemindersLoadingWidget(),
                    EmptyReminders(:final isLoading) =>
                      RemindersEmptyWidget(isLoading: isLoading),
                    ReminderError() => RemindersErrorWidget(
                      onRetry: () => cubit.getReminders(),
                    ),
                    LoadedReminders(
                      :final reminders,
                      :final type,
                      :final isLoading,
                    ) =>
                      RemindersLoadedWidget(
                        reminders: reminders,
                        selectedType: type,
                        isLoading: isLoading,
                      ),
                    _ => const RemindersLoadingWidget(),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}