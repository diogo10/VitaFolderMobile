import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_state.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminder_widget.dart';

class RemindersView extends StatefulWidget {
  const RemindersView({super.key});

  @override
  State<RemindersView> createState() => _RemindersViewState();
}

class _RemindersViewState extends State<RemindersView> {
  @override
  void initState() {
    context.read<RemindersCubit>().getReminders();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RemindersCubit, RemindersState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9F7F4),
          appBar: AppBar(
            title: const Text('Reminders'),
          ),
          body: Builder(builder: (_) {
            if (state is RemindersLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (state is LoadedReminders) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<RemindersCubit>().getReminders();
                },
                child: ListView.builder(
                  itemCount: state.reminders.length,
                  itemBuilder: (_, index) {
                    return ReminderWidget(
                      key: Key(state.reminders[index].id.toString()),
                      title: state.reminders[index].title,
                      body: state.reminders[index].body,
                    );
                  },
                ),
              );
            }

            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            );
          }),
        );
      },
    );
  }
}
