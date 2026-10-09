import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/notes/data/models/note_model.dart';
import 'package:house_mira/features/notes/domain/entities/note_entity.dart';
import 'package:house_mira/features/notes/domain/repository/notes_repository.dart'
    show
        NotesRepository,
        notesFailureGeneric,
        notesFailureNotFound,
        notesFailureOffline;
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
  Future<Either<Failure, List<NoteEntity>>> getNotes(String familyId) async {
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
      return Left(Failure(message: notesFailureGeneric));
    }
  }

  @override
  Future<Either<Failure, int>> getNotesCount(String familyId) async {
    try {
      final count = await _client
          .from('notes')
          .count(CountOption.exact)
          .eq('family_id', familyId);
      return Right(count);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } on SocketException catch (e) {
      debugPrint('Notes offline counting notes: $e');
      return Left(Failure(message: notesFailureOffline));
    } on Object catch (e) {
      debugPrint('Error counting notes: $e');
      return Left(Failure(message: notesFailureGeneric));
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
      if (id == null || id.isEmpty) {
        return Left(Failure(message: notesFailureGeneric));
      }
      return Right(id);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } on SocketException catch (e) {
      debugPrint('Notes offline creating note: $e');
      return Left(Failure(message: notesFailureOffline));
    } on Object catch (e) {
      debugPrint('Error creating note: $e');
      return Left(Failure(message: notesFailureGeneric));
    }
  }

  @override
  Future<Either<Failure, bool>> updateNote(NoteModel note) async {
    try {
      final payload = note.toUpdate();
      // Writes stay bare (no .select()): representation responses on writes
      // trigger backend 42804 errors on this project, so the write is
      // verified with a follow-up read instead (plain SELECTs work).
      await _client.from('notes').update(payload).eq('id', note.id);
      final echoed = await _client
          .from('notes')
          .select('id,title,content,color')
          .eq('id', note.id)
          .maybeSingle();
      if (echoed == null) {
        return Left(Failure(message: notesFailureNotFound));
      }
      // A reported success must actually persist the payload: if the freshly
      // read row differs, the write did not stick, so fail loudly instead
      // of closing the editor with a success message over stale data.
      final persisted =
          echoed['title'] == payload['title'] &&
          echoed['content'] == payload['content'] &&
          echoed['color'] == payload['color'];
      if (!persisted) {
        debugPrint(
          'Notes update not persisted for ${note.id}: '
          'sent=$payload echo=$echoed',
        );
        return Left(Failure(message: notesFailureGeneric));
      }
      return const Right(true);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } on SocketException catch (e) {
      debugPrint('Notes offline updating note: $e');
      return Left(Failure(message: notesFailureOffline));
    } on Object catch (e) {
      debugPrint('Error updating note: $e');
      return Left(Failure(message: notesFailureGeneric));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteNote(String id) async {
    try {
      // Bare delete (see updateNote): verified with a follow-up read.
      await _client.from('notes').delete().eq('id', id);
      final echoed = await _client
          .from('notes')
          .select('id')
          .eq('id', id)
          .maybeSingle();
      if (echoed != null) {
        debugPrint('Notes delete not persisted for $id: row still present');
        return Left(Failure(message: notesFailureGeneric));
      }
      return const Right(true);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } on SocketException catch (e) {
      debugPrint('Notes offline deleting note: $e');
      return Left(Failure(message: notesFailureOffline));
    } on Object catch (e) {
      debugPrint('Error deleting note: $e');
      return Left(Failure(message: notesFailureGeneric));
    }
  }
}
