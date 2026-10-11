import 'package:house_mira_notes/domain/entities/note_entity.dart';

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

/// Free-tier cap hit that preserves the current list.
///
/// Emitted by [NotesCubit.createNote] instead of [NotesFailure] when a
/// free-tier user hits the notes cap: it carries the
/// reloaded notes so the list view keeps rendering (rather than
/// switching to a full-screen error) while the editor surfaces the
/// limit message with an upgrade action.
class NotesLimitReached extends NotesState {
  const NotesLimitReached(this.notes);
  final List<NoteEntity> notes;
}

/// Localized failure (offline, RLS denial, not-found, generic).
class NotesFailure extends NotesState {
  const NotesFailure(this.message);
  final String message;
}
