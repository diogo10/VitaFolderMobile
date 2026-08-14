import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/reminders/data/models/reminder_model.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';

abstract interface class ReminderRepository {
  Future<Either<Failure, List<ReminderEntity>>> getReminders(String familyId);

  Future<Either<Failure, List<ReminderEntity>>> getRemindersByTypeAndFamily({
    required ReminderType type,
    required String familyId,
  });

  Future<Either<Failure, bool>> createReminder(
    ReminderModel reminder,
    String familyId,
  );

  Future<Either<Failure, bool>> removeReminder(String id);
}
