import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';
import 'package:vita_folder_mobile/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_state.dart';

class RemindersCubit extends Cubit<RemindersState> {
  GetReminderUsecase getReminderUsecase;
  PeopleRepository peopleRepository;
  AuthService authService;

  RemindersCubit({
    required this.getReminderUsecase,
    required this.peopleRepository,
    required this.authService,
  }) : super(ReminderInitialState());

  Future<void> getReminders({String? familyId}) async {
    emit(RemindersLoading());

    final resolvedFamilyId = familyId ?? await _resolveFamilyId();
    if (resolvedFamilyId == null) {
      emit(ReminderError());
      return;
    }

    final result = await getReminderUsecase(resolvedFamilyId);

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

  Future<String?> _resolveFamilyId() async {
    final userId = authService.currentUserId;
    if (userId.isEmpty) {
      return null;
    }
    final familyIds = await peopleRepository.getFamilyIdsForUser(userId);
    return familyIds.isEmpty ? null : familyIds.first;
  }
}