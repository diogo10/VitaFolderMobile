import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';
import 'package:vita_folder_mobile/features/reminders/data/models/reminder_model.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/domain/usecase/create_reminder_usecase.dart';
import 'package:vita_folder_mobile/features/reminders/domain/usecase/update_reminder_usecase.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/create_reminder_state.dart';

class CreateReminderCubit extends Cubit<CreateReminderState> {
  final CreateReminderUsecase _createReminderUsecase;
  final UpdateReminderUsecase _updateReminderUsecase;
  final AuthService authService;
  final PeopleRepository _peopleRepository;

  CreateReminderCubit({
    required CreateReminderUsecase createReminderUsecase,
    required UpdateReminderUsecase updateReminderUsecase,
    required this.authService,
    required PeopleRepository peopleRepository,
  }) : _createReminderUsecase = createReminderUsecase,
       _updateReminderUsecase = updateReminderUsecase,
       _peopleRepository = peopleRepository,
       super(CreateReminderInitial());

  Future<void> createReminder({
    required String title,
    required String body,
    required ReminderType type,
    required DateTime? dueDate,
    required String repeatRule,
  }) async {
    emit(CreateReminderLoading());

    final familyId = await _resolveFamilyId();
    if (familyId == null) {
      emit(CreateReminderError(message: 'No family found'));
      return;
    }

    final userId = authService.currentUserId;
    if (userId == null) {
      emit(CreateReminderError(message: 'Authentication required'));
      return;
    }

    final reminder = ReminderModel(
      title: title,
      body: body,
      id: '',
      type: type,
      dueDate: dueDate?.toIso8601String() ?? '',
      repeatRule: repeatRule,
      status: 'pending',
      createdBy: userId,
      createdAt: DateTime.now().toIso8601String(),
    );

    final result = await _createReminderUsecase(reminder, familyId);

    result.fold(
      (err) => emit(CreateReminderError(message: err.message)),
      (_) => emit(CreateReminderSuccess()),
    );
  }

  Future<void> updateReminder({
    required ReminderEntity reminder,
    required String title,
    required String body,
    required ReminderType type,
    required DateTime? dueDate,
    required String repeatRule,
  }) async {
    emit(CreateReminderLoading());

    final reminderModel = ReminderModel(
      title: title,
      body: body,
      id: reminder.id,
      type: type,
      dueDate: dueDate?.toIso8601String() ?? '',
      repeatRule: repeatRule,
      status: reminder.status,
      createdBy: reminder.createdBy,
      createdAt: reminder.createdAt,
    );

    final result = await _updateReminderUsecase(reminderModel);

    result.fold(
      (err) => emit(CreateReminderError(message: err.message)),
      (_) => emit(UpdatedReminderSuccess()),
    );
  }

  Future<String?> _resolveFamilyId() async {
    final userId = authService.currentUserId;
    if (userId == null) {
      return null;
    }
    final familyIds = await _peopleRepository.getFamilyIdsForUser(userId);
    return familyIds.isEmpty ? null : familyIds.first;
  }
}
