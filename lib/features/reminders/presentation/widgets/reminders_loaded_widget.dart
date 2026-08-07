import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminder_widget.dart';

class RemindersLoadedWidget extends StatelessWidget {
  final List<ReminderEntity> reminders;
  final ReminderType? selectedType;
  final bool isLoading;

  const RemindersLoadedWidget({
    super.key,
    required this.reminders,
    this.selectedType,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RemindersCubit>();

    return RefreshIndicator(
      onRefresh: () => cubit.getReminders(type: selectedType),
      child: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return ReminderWidget(
                key: Key(reminder.id),
                reminder: reminder,
              );
            },
          ),
          if (isLoading)
            const Positioned(
              top: 0,
              left: 24,
              right: 24,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}