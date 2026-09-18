import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/reminders/data/models/reminder_model.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:house_mira/features/reminders/domain/repository/reminder_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      return Left(Failure(message: e.message));
    } on Object catch (e) {
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
    } on Object catch (e) {
      debugPrint('Error getting reminders by type and family: $e');
      return Left(Failure());
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
      if (id == null || id.isEmpty) return Left(Failure());
      return Right(id);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } on Object catch (e) {
      debugPrint('Error creating reminder: $e');
      return Left(Failure());
    }
  }

  @override
  Future<Either<Failure, bool>> updateReminder(ReminderModel reminder) async {
    try {
      final input = reminder.toUpdate();
      await _client.from('reminders').update(input).eq('id', reminder.id);
      return const Right(true);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } on Object catch (e) {
      debugPrint('Error updating reminder: $e');
      return Left(Failure());
    }
  }

  @override
  Future<Either<Failure, bool>> removeReminder(String id) async {
    try {
      await _client.from('reminders').delete().eq('id', id);
      return const Right(true);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } on Object catch (e) {
      debugPrint('Error removing reminder: $e');
      return Left(Failure());
    }
  }
}
