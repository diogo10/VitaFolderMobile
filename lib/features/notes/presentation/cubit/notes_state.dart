import 'package:house_mira/features/notes/domain/entities/note_entity.dart';

/// Sealed notes list lifecycle (FR-102).
///
/// Every cubit method emits [NotesLoading] first then exactly one outcome.
/// Mutations emit [NoteActionSuccess] transiently before reloading.
sealed class NotesState {
  const NotesState();
}

/// Initial state before any load.
class NotesInitial extends NotesState {
  const NotesInitial();
}

/// Loading indicator (also used for pull-to-refresh re-sync).
class NotesLoading extends NotesState {
  const NotesLoading();
}

/// Signed-out state (no `currentUserId`).
class NotesUnauthenticated extends NotesState {
  const NotesUnauthenticated();
}

/// Populated (or empty-list) outcome.
class NotesLoaded extends NotesState {
  const NotesLoaded(this.notes);
  final List<NoteEntity> notes;
}

/// Transient mutation success before the reload sequence.
class NoteActionSuccess extends NotesState {
  const NoteActionSuccess();
}

/// Localized failure (offline, RLS denial, not-found, generic).
class NotesFailure extends NotesState {
  const NotesFailure(this.message);
  final String message;
}
