import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';

abstract interface class ReminderRepository {
  Future<Either<Failure, List<ReminderEntity>>> getReminders();
}
