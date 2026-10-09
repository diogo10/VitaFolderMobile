import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/reminders/data/models/reminder_model.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';

/// Failure message codes emitted at the repository/cubit boundary.
///
/// The presentation layer maps known codes to localized strings and every
/// unknown code falls back to the generic error (never raw English).
/// [remindersFailureOffline] maps to the generic reminders error; there is
/// no dedicated offline string for reminders. The generic suffices because
/// the reminders error surface already offers a retry action
/// (`remindersErrorRetry`), so an offline-specific copy would add no new
/// affordance — the user retries the same way either way.
const String remindersFailureOffline = 'offline';

/// Unexpected error mapping to the generic reminders error
/// (never raw English).
const String remindersFailureGeneric = 'generic';

abstract interface class ReminderRepository {
  Future<Either<Failure, List<ReminderEntity>>> getReminders(String familyId);

  /// Head-count of reminders in one family.
  ///
  /// Used by the free-tier limit check so it never fetches the full list.
  Future<Either<Failure, int>> getRemindersCount(String familyId);

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
