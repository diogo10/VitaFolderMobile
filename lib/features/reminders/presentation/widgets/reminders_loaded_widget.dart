import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminder_widget.dart';

class RemindersLoadedWidget extends StatelessWidget {
  final List<ReminderEntity> reminders;

  const RemindersLoadedWidget({super.key, required this.reminders});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<RemindersCubit>().getReminders();
      },
      child: ListView.builder(
        itemCount: reminders.length,
        itemBuilder: (_, index) {
          return ReminderWidget(
            key: Key(reminders[index].id.toString()),
            title: reminders[index].title,
            body: reminders[index].body,
          );
        },
      ),
    );
  }
}
