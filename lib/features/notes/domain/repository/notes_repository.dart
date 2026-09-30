import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/notes/data/models/note_model.dart';
import 'package:house_mira/features/notes/domain/entities/note_entity.dart';

/// Failure message codes emitted at the repository/cubit boundary.
///
/// The presentation layer maps them to localized strings
/// (`notesErrorNotFound`, `notesErrorOffline`, `notesErrorNoFamily`,
/// `notesErrorGeneric`); raw English never reaches the UI.
const String notesFailureNotFound = 'not-found';
const String notesFailureOffline = 'offline';
const String notesFailureNoFamily = 'no-family';

/// Notes repository contract.
///
/// All methods return `Future<Either<Failure, T>>` (FR-103). Errors are
/// mapped to `Failure` at the `NotesRepositoryImpl` boundary; no Supabase
/// types leak past it.
abstract interface class NotesRepository {
  /// Lists notes scoped to one family, ordered `created_at DESC`.
  Future<Either<Failure, List<NoteEntity>>> getNotes(String familyId);

  /// Creates the note and returns the created row id.
  Future<Either<Failure, String>> createNote(
    NoteModel note,
    String familyId,
  );

  /// Last-write-wins update. Returns `true` on success; a stale/missing
  /// row yields `Left(Failure)` with a not-found message.
  Future<Either<Failure, bool>> updateNote(NoteModel note);

  /// Hard delete. Returns `true` on success; a stale/missing row yields
  /// `Left(Failure)` with a not-found message.
  Future<Either<Failure, bool>> deleteNote(String id);
}
