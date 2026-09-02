import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/reminders/data/models/reminder_model.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';

class UpdateReminderUsecase {
  final ReminderRepository repository;

  UpdateReminderUsecase({required this.repository});

  Future<Either<Failure, bool>> call(ReminderModel reminder) async {
    return await repository.updateReminder(reminder);
  }
}
