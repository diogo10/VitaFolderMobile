import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_state.dart';

class RemindersCubit extends Cubit<RemindersState> {
  GetReminderUsecase getReminderUsecase;

  RemindersCubit({required this.getReminderUsecase}) : super(ReminderInitialState());

  Future<void> getReminders() async {
    emit(RemindersLoading());
    final reminders = await getReminderUsecase();

    reminders.fold(
      (err) => emit(ReminderError()),
      (reminders) => emit(LoadedReminders(reminders: reminders)),
    );
  }
}
