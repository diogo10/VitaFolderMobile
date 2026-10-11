import 'package:fpdart/fpdart.dart';
import 'package:house_mira_core/errors/failure.dart';
import 'package:house_mira_reminders/data/models/reminder_model.dart';
import 'package:house_mira_reminders/domain/repository/reminder_repository.dart';

class UpdateReminderUsecase {

  UpdateReminderUsecase({required this.repository});
  final ReminderRepository repository;

  Future<Either<Failure, bool>> call(ReminderModel reminder) async {
    return repository.updateReminder(reminder);
  }
}
