import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/domain/repository/reminder_repository.dart';

class GetReminderUsecase {
  final ReminderRepository repository;
  final PeopleRepository peopleRepository;

  GetReminderUsecase({required this.repository, required this.peopleRepository});

  Future<Either<Failure, List<ReminderEntity>>> call(
    String familyId, {
    ReminderType? type,
  }) async {
    final remindersResult = type == null
        ? await repository.getReminders(familyId)
        : await repository.getRemindersByTypeAndFamily(
            type: type,
            familyId: familyId,
          );

    return remindersResult.fold(
      (err) => Left(Failure(message: err.message)),
      (reminders) async {
        final people = await peopleRepository.getProfilesWithRoleForFamily(familyId);
        final peopleById = {
          for (final person in people)
            if (person.id != null) person.id!: person,
        };

        return Right(
          reminders.map((reminder) {
            final person = peopleById[reminder.createdBy];
            if (person == null) {
              return reminder;
            }
            return reminder.copyWith(
              createdBy: person.name ?? reminder.createdBy,
            );
          }).toList(),
        );
      },
    );
  }
}