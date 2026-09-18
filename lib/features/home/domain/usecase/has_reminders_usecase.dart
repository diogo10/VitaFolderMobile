import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';

class HasRemindersUsecase {

  HasRemindersUsecase({
    required this.authService,
    required this.peopleRepository,
    required this.reminderRepository,
  });
  final AuthService authService;
  final PeopleRepository peopleRepository;
  final ReminderRepository reminderRepository;

  Future<Either<Failure, bool>> call() async {
    final userId = authService.currentUserId;
    if (userId == null) {
      return const Right(false);
    }

    final familyIds = await peopleRepository.getFamilyIdsForUser(userId);
    final familyId = familyIds.isEmpty ? null : familyIds.first;
    if (familyId == null) {
      return const Right(false);
    }

    final result = await reminderRepository.getReminders(familyId);
    return result.map((reminders) => reminders.isNotEmpty);
  }
}
