import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/repository/reminder_repository.dart';

class GetReminderUsecase {
  final ReminderRepository repository;

  GetReminderUsecase({required this.repository});

  Future<Either<Failure, List<ReminderEntity>>> call() async {
    return await repository.getReminders();
  }
}
