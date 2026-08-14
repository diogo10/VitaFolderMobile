import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/reminders/data/models/reminder_model.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/domain/repository/reminder_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final SupabaseClient _client;

  ReminderRepositoryImpl({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  Future<Either<Failure, List<ReminderEntity>>> getReminders(String familyId) async {
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
      return Left(Failure(message: e.message));
    } catch (e) {
      debugPrint('Error getting the reminders: $e');
      return Left(Failure());
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
      return Left(Failure(message: e.message));
    } catch (e) {
      debugPrint('Error getting reminders by type and family: $e');
      return Left(Failure());
    }
  }

  @override
  Future<Either<Failure, bool>> createReminder(ReminderModel reminder, String familyId) async {
    try {
      final input = reminder.toCreate(familyId);
      await _client.from('reminders').insert(input);
      return Right(true);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } catch (e) {
      debugPrint('Error creating reminder: $e');
      return Left(Failure());
    }
  }

  @override
  Future<Either<Failure, bool>> removeReminder(int id) async {
    try {
      await _client.from('reminders').delete().eq('id', id);
      return Right(true);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } catch (e) {
      debugPrint('Error removing reminder: $e');
      return Left(Failure());
    }
  }
}