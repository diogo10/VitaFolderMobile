import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira_core/errors/failure.dart';
import 'package:house_mira_reminders/data/models/reminder_model.dart';
import 'package:house_mira_reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira_reminders/domain/entities/reminder_type.dart';
import 'package:house_mira_reminders/domain/repository/reminder_repository.dart'
    show ReminderRepository, remindersFailureGeneric, remindersFailureOffline;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of [ReminderRepository].
///
/// Supabase errors are mapped to [Failure] at this boundary
/// (`WriteBlockedFailure` → preserved as-is so callers can branch on type,
/// other `Failure` → message passthrough, [SocketException] → offline code,
/// `on Object` → generic). Raw English never originates here: every
/// synthesized failure carries [remindersFailureGeneric].
///
/// TODO(diogohenrique): replace the `dart:io` [SocketException] catches
/// with a cross-platform offline signal — `dart:io` breaks web
/// compilation and misses web network errors. Until then this stays
/// mobile-only (the app ships Android/iOS; there is no `web/` target).
class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRepositoryImpl({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;

  @override
  Future<Either<Failure, List<ReminderEntity>>> getReminders(
    String familyId,
  ) async {
    try {
      final response = await _client
          .from('reminders')
          .select()
          .eq('family_id', familyId);
      final data = (response as List)
          .map((r) => ReminderModel.fromMap(r as Map<String, dynamic>))
          .toList();
      return Right(data);
    } on Failure catch (e) {
      if (e is WriteBlockedFailure) return Left(e);
      return Left(Failure(message: e.message));
    } on SocketException catch (e) {
      debugPrint('Reminders offline getting the reminders: $e');
      return Left(Failure(message: remindersFailureOffline));
    } on Object catch (e) {
      debugPrint('Error getting the reminders: $e');
      return Left(Failure(message: remindersFailureGeneric));
    }
  }

  @override
  Future<Either<Failure, int>> getRemindersCount(String familyId) async {
    try {
      final count = await _client
          .from('reminders')
          .count(CountOption.exact)
          .eq('family_id', familyId);
      return Right(count);
    } on Failure catch (e) {
      if (e is WriteBlockedFailure) return Left(e);
      return Left(Failure(message: e.message));
    } on SocketException catch (e) {
      debugPrint('Reminders offline counting reminders: $e');
      return Left(Failure(message: remindersFailureOffline));
    } on Object catch (e) {
      debugPrint('Error counting reminders: $e');
      return Left(Failure(message: remindersFailureGeneric));
    }
  }

  @override
  Future<Either<Failure, List<ReminderEntity>>> getRemindersByTypeAndFamily({
    required ReminderType type,
    required String familyId,
  }) async {
    try {
      final response = await _client
          .from('reminders')
          .select()
          .eq('type', type.value)
          .eq('family_id', familyId);
      final data = (response as List)
          .map((r) => ReminderModel.fromMap(r as Map<String, dynamic>))
          .toList();
      return Right(data);
    } on Failure catch (e) {
      if (e is WriteBlockedFailure) return Left(e);
      return Left(Failure(message: e.message));
    } on SocketException catch (e) {
      debugPrint('Reminders offline getting reminders by type: $e');
      return Left(Failure(message: remindersFailureOffline));
    } on Object catch (e) {
      debugPrint('Error getting reminders by type and family: $e');
      return Left(Failure(message: remindersFailureGeneric));
    }
  }

  @override
  Future<Either<Failure, String>> createReminder(
    ReminderModel reminder,
    String familyId,
  ) async {
    try {
      final input = reminder.toCreate(familyId);
      final created = await _client
          .from('reminders')
          .insert(input)
          .select('id')
          .single();
      final id = created['id']?.toString();
      if (id == null || id.isEmpty) {
        return Left(Failure(message: remindersFailureGeneric));
      }
      return Right(id);
    } on Failure catch (e) {
      if (e is WriteBlockedFailure) return Left(e);
      return Left(Failure(message: e.message));
    } on SocketException catch (e) {
      debugPrint('Reminders offline creating reminder: $e');
      return Left(Failure(message: remindersFailureOffline));
    } on Object catch (e) {
      debugPrint('Error creating reminder: $e');
      return Left(Failure(message: remindersFailureGeneric));
    }
  }

  @override
  Future<Either<Failure, bool>> updateReminder(ReminderModel reminder) async {
    try {
      final input = reminder.toUpdate();
      // Writes stay bare (no .select()): representation responses on writes
      // trigger backend 42804 errors on this project, so the write is
      // verified with a follow-up read instead (plain SELECTs work).
      await _client.from('reminders').update(input).eq('id', reminder.id);
      final echoed = await _client
          .from('reminders')
          .select('id,title,type,body,repeat_rule')
          .eq('id', reminder.id)
          .maybeSingle();
      if (echoed == null) return Left(WriteBlockedFailure());
      // due_at is excluded: the server timestamptz formatting differs from
      // the ISO string sent, so exact equality never holds for it.
      final persisted =
          echoed['title'] == input['title'] &&
          echoed['type'] == input['type'] &&
          echoed['body'] == input['body'] &&
          echoed['repeat_rule'] == input['repeat_rule'];
      if (!persisted) {
        debugPrint(
          'Reminder update not persisted for ${reminder.id}: '
          'sent=$input echo=$echoed',
        );
        return Left(WriteBlockedFailure());
      }
      return const Right(true);
    } on Failure catch (e) {
      if (e is WriteBlockedFailure) return Left(e);
      return Left(Failure(message: e.message));
    } on SocketException catch (e) {
      debugPrint('Reminders offline updating reminder: $e');
      return Left(Failure(message: remindersFailureOffline));
    } on Object catch (e) {
      debugPrint('Error updating reminder: $e');
      return Left(Failure(message: remindersFailureGeneric));
    }
  }

  @override
  Future<Either<Failure, bool>> removeReminder(String id) async {
    try {
      // Bare delete (see updateReminder): verified with a follow-up read.
      await _client.from('reminders').delete().eq('id', id);
      final echoed = await _client
          .from('reminders')
          .select('id')
          .eq('id', id)
          .maybeSingle();
      if (echoed != null) {
        debugPrint('Reminder delete not persisted for $id: row still present');
        return Left(WriteBlockedFailure());
      }
      return const Right(true);
    } on Failure catch (e) {
      if (e is WriteBlockedFailure) return Left(e);
      return Left(Failure(message: e.message));
    } on SocketException catch (e) {
      debugPrint('Reminders offline removing reminder: $e');
      return Left(Failure(message: remindersFailureOffline));
    } on Object catch (e) {
      debugPrint('Error removing reminder: $e');
      return Left(Failure(message: remindersFailureGeneric));
    }
  }
}
