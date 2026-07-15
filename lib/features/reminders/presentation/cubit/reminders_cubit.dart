import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_state.dart';

class RemindersCubit extends Cubit<RemindersState> {
  GetReminderUsecase getReminderUsecase;

  RemindersCubit({required this.getReminderUsecase}) : super(ReminderInitialState());

  Future<void> getReminders() async {
    emit(RemindersLoading());
    final result = await getReminderUsecase();

    result.fold(
      (err) => emit(ReminderError()),
      (reminders) {
        if (reminders.isEmpty) {
          emit(EmptyReminders());
        } else {
          emit(LoadedReminders(reminders: reminders));
        }
      },
    );
  }
}
