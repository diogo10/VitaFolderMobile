import 'package:fpdart/fpdart.dart';
import 'package:house_mira_core/errors/failure.dart';
import 'package:house_mira_reminders/data/models/reminder_model.dart';
import 'package:house_mira_reminders/domain/repository/reminder_repository.dart';

class CreateReminderUsecase {

  CreateReminderUsecase({required this.repository});
  final ReminderRepository repository;

  Future<Either<Failure, String>> call(
    ReminderModel reminder,
    String familyId,
  ) async {
    return repository.createReminder(reminder, familyId);
  }
}
