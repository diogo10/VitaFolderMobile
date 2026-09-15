import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/reminders/data/models/reminder_model.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';

class CreateReminderUsecase {
  final ReminderRepository repository;

  CreateReminderUsecase({required this.repository});

  Future<Either<Failure, String>> call(
    ReminderModel reminder,
    String familyId,
  ) async {
    return await repository.createReminder(reminder, familyId);
  }
}
