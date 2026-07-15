import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_state.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminders_empty_widget.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminders_error_widget.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminders_loaded_widget.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminders_loading_widget.dart';

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
    return BlocBuilder<RemindersCubit, RemindersState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9F7F4),
          body: switch (state) {
            RemindersLoading() => const RemindersLoadingWidget(),
            EmptyReminders() => const RemindersEmptyWidget(),
            ReminderError() => RemindersErrorWidget(
              onRetry: () => context.read<RemindersCubit>().getReminders(),
            ),
            LoadedReminders(:final reminders) => RemindersLoadedWidget(reminders: reminders),
            _ => const RemindersLoadingWidget(),
          },
        );
      },
    );
  }
}
