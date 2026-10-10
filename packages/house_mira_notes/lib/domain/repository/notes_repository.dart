import 'package:fpdart/fpdart.dart';
import 'package:house_mira_core/errors/failure.dart';
import 'package:house_mira_notes/data/models/note_model.dart';
import 'package:house_mira_notes/domain/entities/note_entity.dart';

/// Failure message codes emitted at the repository/cubit boundary.
///
/// The presentation layer maps them to localized strings
/// (`notesErrorNotFound`, `notesErrorOffline`, `notesErrorNoFamily`,
/// `notesErrorGeneric`); raw English never reaches the UI.
/// [notesFailureGeneric] maps to `notesErrorGeneric` and is also the
/// fallback for any unrecognized code.
///
/// The free-tier cap is surfaced as the NotesLimitReached state (which
/// carries the list), never as a failure code, so capped users keep the
/// list behind the limit message with an upgrade action.
const String notesFailureNotFound = 'not-found';
const String notesFailureOffline = 'offline';
const String notesFailureNoFamily = 'no-family';

/// Unexpected error mapping to the generic notes error (never raw English).
const String notesFailureGeneric = 'generic';

/// Notes repository contract.
///
/// All methods return `Future<Either<Failure, T>>` (FR-103). Errors are
/// mapped to `Failure` at the `NotesRepositoryImpl` boundary; no Supabase
/// types leak past it.
abstract interface class NotesRepository {
  /// Lists notes scoped to one family, ordered `created_at DESC`.
  Future<Either<Failure, List<NoteEntity>>> getNotes(String familyId);

  /// Head-count of notes in one family.
  ///
  /// Used by the free-tier limit check so it never fetches the full list.
  Future<Either<Failure, int>> getNotesCount(String familyId);

  /// Creates the note and returns the created row id.
  Future<Either<Failure, String>> createNote(NoteModel note, String familyId);

  /// Last-write-wins update. Returns `true` on success; a stale/missing
  /// row yields `Left(Failure)` with a not-found message.
  Future<Either<Failure, bool>> updateNote(NoteModel note);

  /// Hard delete. Returns `true` on success; a stale/missing row yields
  /// `Left(Failure)` with a not-found message.
  Future<Either<Failure, bool>> deleteNote(String id);
}
