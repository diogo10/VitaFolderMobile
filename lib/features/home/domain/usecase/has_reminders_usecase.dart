import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';

class HasRemindersUsecase {
  final AuthService authService;
  final PeopleRepository peopleRepository;
  final ReminderRepository reminderRepository;

  HasRemindersUsecase({
    required this.authService,
    required this.peopleRepository,
    required this.reminderRepository,
  });

  Future<Either<Failure, bool>> call() async {
    final userId = authService.currentUserId;
    if (userId == null) {
      return Right(false);
    }

    final familyIds = await peopleRepository.getFamilyIdsForUser(userId);
    final familyId = familyIds.isEmpty ? null : familyIds.first;
    if (familyId == null) {
      return Right(false);
    }

    final result = await reminderRepository.getReminders(familyId);
    return result.map((reminders) => reminders.isNotEmpty);
  }
}
