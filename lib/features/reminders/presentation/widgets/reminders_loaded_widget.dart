import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminders_header_widget.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminder_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class RemindersLoadedWidget extends StatelessWidget {
  final List<ReminderEntity> reminders;

  const RemindersLoadedWidget({super.key, required this.reminders});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<RemindersCubit>().getReminders();
        },
        child: ListView.separated(
          padding: const EdgeInsets.only(top: 20, bottom: 24),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: reminders.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RemindersHeaderWidget(
                    title: l.remindersHeaderTitle,
                    subtitle: l.remindersHeaderSubtitle,
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }

            final reminder = reminders[index - 1];
            return ReminderWidget(
              key: Key(reminder.id),
              reminder: reminder,
            );
          },
        ),
      ),
    );
  }
}