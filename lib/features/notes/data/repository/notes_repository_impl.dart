import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/notes/data/models/note_model.dart';
import 'package:house_mira/features/notes/domain/entities/note_entity.dart';
import 'package:house_mira/features/notes/domain/repository/notes_repository.dart'
    show NotesRepository, notesFailureNotFound, notesFailureOffline;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of [NotesRepository].
///
/// Supabase errors are mapped to [Failure] at this boundary
/// (`on Failure` → message passthrough, [SocketException] → offline code,
/// `on Object` → generic).
class NotesRepositoryImpl implements NotesRepository {
  NotesRepositoryImpl({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;

  @override
  Future<Either<Failure, List<NoteEntity>>> getNotes(
    String familyId,
  ) async {
    try {
      final response = await _client
          .from('notes')
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: false);
      final rows = response as List;
      final notes = <NoteEntity>[];
      for (final row in rows) {
        final note = NoteEntity.from(row);
        if (note != null) notes.add(note);
      }
      return Right(notes);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } on SocketException catch (e) {
      debugPrint('Notes offline getting the notes: $e');
      return Left(Failure(message: notesFailureOffline));
    } on Object catch (e) {
      debugPrint('Error getting the notes: $e');
      return Left(Failure(message: ''));
    }
  }

  @override
  Future<Either<Failure, String>> createNote(
    NoteModel note,
    String familyId,
  ) async {
    try {
      final created = await _client
          .from('notes')
          .insert(note.toCreate(familyId))
          .select('id')
          .single();
      final id = created['id']?.toString();
      if (id == null || id.isEmpty) return Left(Failure(message: ''));
      return Right(id);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } on SocketException catch (e) {
      debugPrint('Notes offline creating note: $e');
      return Left(Failure(message: notesFailureOffline));
    } on Object catch (e) {
      debugPrint('Error creating note: $e');
      return Left(Failure(message: ''));
    }
  }

  @override
  Future<Either<Failure, bool>> updateNote(NoteModel note) async {
    try {
      final updated = await _client
          .from('notes')
          .update(note.toUpdate())
          .eq('id', note.id)
          .select('id');
      if ((updated as List).isEmpty) {
        return Left(Failure(message: notesFailureNotFound));
      }
      return const Right(true);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } on SocketException catch (e) {
      debugPrint('Notes offline updating note: $e');
      return Left(Failure(message: notesFailureOffline));
    } on Object catch (e) {
      debugPrint('Error updating note: $e');
      return Left(Failure(message: ''));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteNote(String id) async {
    try {
      final deleted = await _client
          .from('notes')
          .delete()
          .eq('id', id)
          .select('id');
      if ((deleted as List).isEmpty) {
        return Left(Failure(message: notesFailureNotFound));
      }
      return const Right(true);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } on SocketException catch (e) {
      debugPrint('Notes offline deleting note: $e');
      return Left(Failure(message: notesFailureOffline));
    } on Object catch (e) {
      debugPrint('Error deleting note: $e');
      return Left(Failure(message: ''));
    }
  }
}
