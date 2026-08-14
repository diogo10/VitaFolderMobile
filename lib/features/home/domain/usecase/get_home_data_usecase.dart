import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/home/domain/entities/home_entity.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/family_entity.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/repository/reminder_repository.dart';

class GetHomeDataUsecase {
  final PeopleRepository peopleRepository;
  final ReminderRepository reminderRepository;
  final AuthService authService;

  GetHomeDataUsecase({
    required this.peopleRepository,
    required this.reminderRepository,
    required this.authService,
  });

  Future<Either<Exception, HomeEntity>> call() async {
    if (!authService.isLoggedIn()) {
      return Left(NoDataException());
    }

    final peopleResult = await peopleRepository.getPeople();
    return peopleResult.fold((err) => Left(err), (people) async {
      final familyResult = await peopleRepository.getMyFamily();
      final family = familyResult.getOrElse(
        (_) => FamilyEntity(name: '', inviteCode: ''),
      );

      final roles = await peopleRepository.getMyFamilyRole();
      final familyIds = await peopleRepository.getFamilyIdsForUser(
        authService.currentUserId ?? '',
      );
      final familyId = familyIds.isEmpty ? null : familyIds.first;

      final reminders = familyId == null
          ? const <ReminderEntity>[]
          : await _fetchReminders(familyId);

      return Right(
        HomeEntity(
          peopleInCircle: people,
          familyName: family.name,
          myRole: roles.isEmpty ? '' : roles.first,
          activeMembers: people.length,
          reminders: reminders,
          hasReminders: reminders.isNotEmpty,
        ),
      );
    });
  }

  Future<List<ReminderEntity>> _fetchReminders(String familyId) async {
    final result = await reminderRepository.getReminders(familyId);
    return result.getOrElse((_) => const <ReminderEntity>[]);
  }
}
