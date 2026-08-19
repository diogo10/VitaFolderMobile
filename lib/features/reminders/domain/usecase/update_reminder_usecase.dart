import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/reminders/data/models/reminder_model.dart';
import 'package:vita_folder_mobile/features/reminders/domain/repository/reminder_repository.dart';

class UpdateReminderUsecase {
  final ReminderRepository repository;

  UpdateReminderUsecase({required this.repository});

  Future<Either<Failure, bool>> call(ReminderModel reminder) async {
    return await repository.updateReminder(reminder);
  }
}
