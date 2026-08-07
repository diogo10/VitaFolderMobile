import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_state.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';
import 'package:vita_folder_mobile/features/reminders/domain/repository/reminder_repository.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetHomeDataUsecase getHomeDataUsecase;
  final ReminderRepository reminderRepository;
  final PeopleRepository peopleRepository;
  final AuthService authService;

  HomeCubit({
    required this.getHomeDataUsecase,
    required this.reminderRepository,
    required this.peopleRepository,
    required this.authService,
  }) : super(HomeInitial());

  Future<void> getHomeData() async {
    emit(HomeLoading());
    final result = await getHomeDataUsecase();

    await result.fold(
      (err) async => _handleError(err),
      (data) async {
        final hasReminders = await _hasReminders();
        emit(HomeLoaded(data: data.copyWith(hasReminders: hasReminders)));
      },
    );
  }

  Future<bool> _hasReminders() async {
    final userId = authService.currentUserId;
    if (userId.isEmpty) {
      return false;
    }

    final familyIds = await peopleRepository.getFamilyIdsForUser(userId);
    final familyId = familyIds.isEmpty ? null : familyIds.first;
    if (familyId == null) {
      return false;
    }

    final remindersResult = await reminderRepository.getReminders(familyId);
    return remindersResult.fold(
      (_) => false,
      (reminders) => reminders.isNotEmpty,
    );
  }

  Future<void> _handleError(Exception err) async {
    if (err is NoDataException) {
      final hasReminders = await _hasReminders();
      emit(HomeEmpty(hasReminders: hasReminders));
    } else {
      emit(HomeError());
    }
  }
}
