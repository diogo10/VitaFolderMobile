import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_state.dart';

class RemindersCubit extends Cubit<RemindersState> {
  GetReminderUsecase getReminderUsecase;
  PeopleRepository peopleRepository;
  AuthService authService;

  ReminderType? _selectedType;
  ReminderType? get selectedType => _selectedType;

  RemindersCubit({
    required this.getReminderUsecase,
    required this.peopleRepository,
    required this.authService,
  }) : super(ReminderInitialState());

  Future<void> getReminders({String? familyId, ReminderType? type}) async {
    _selectedType = type;

    final current = state;
    if (current is LoadedReminders) {
      emit(
        LoadedReminders(
          reminders: current.reminders,
          type: type,
          isLoading: true,
        ),
      );
    } else if (current is EmptyReminders) {
      emit(EmptyReminders(type: type, isLoading: true));
    } else {
      emit(RemindersLoading());
    }

    final resolvedFamilyId = familyId ?? await _resolveFamilyId();
    if (resolvedFamilyId == null) {
      emit(ReminderError());
      return;
    }

    final result = await getReminderUsecase(resolvedFamilyId, type: type);

    result.fold((err) => emit(ReminderError()), (reminders) {
      if (reminders.isEmpty) {
        emit(EmptyReminders(type: type));
      } else {
        emit(LoadedReminders(reminders: reminders, type: type));
      }
    });
  }

  Future<String?> _resolveFamilyId() async {
    final userId = authService.currentUserId;
    if (userId == null) {
      return null;
    }
    final familyIds = await peopleRepository.getFamilyIdsForUser(userId);
    return familyIds.isEmpty ? null : familyIds.first;
  }
}
