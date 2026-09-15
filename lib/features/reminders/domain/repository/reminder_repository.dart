import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/reminders/data/models/reminder_model.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';

abstract interface class ReminderRepository {
  Future<Either<Failure, List<ReminderEntity>>> getReminders(String familyId);

  Future<Either<Failure, List<ReminderEntity>>> getRemindersByTypeAndFamily({
    required ReminderType type,
    required String familyId,
  });

  /// Creates the reminder and returns the created id so callers can
  /// schedule per-device notifications for it.
  Future<Either<Failure, String>> createReminder(
    ReminderModel reminder,
    String familyId,
  );

  Future<Either<Failure, bool>> updateReminder(ReminderModel reminder);

  Future<Either<Failure, bool>> removeReminder(String id);
}
