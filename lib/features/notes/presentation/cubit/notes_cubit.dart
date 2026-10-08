import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/features/notes/application/is_at_note_limit_usecase.dart';
import 'package:house_mira/features/notes/data/models/note_model.dart';
import 'package:house_mira/features/notes/domain/entities/note_entity.dart';
import 'package:house_mira/features/notes/domain/repository/notes_repository.dart'
    show notesFailureLimitReached, notesFailureNoFamily, notesFailureUnknown;
import 'package:house_mira/features/notes/domain/usecase/create_note_usecase.dart';
import 'package:house_mira/features/notes/domain/usecase/delete_note_usecase.dart';
import 'package:house_mira/features/notes/domain/usecase/get_notes_usecase.dart';
import 'package:house_mira/features/notes/domain/usecase/update_note_usecase.dart';
import 'package:house_mira/features/notes/presentation/cubit/notes_state.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';

/// Single cubit for all Notes business logic (FR-102).
///
/// No Supabase imports here — all data access flows through use-cases
/// and repositories. Every method emits [NotesLoading] first then exactly
/// one outcome; mutations emit [NoteActionSuccess] then reload.
/// Family scope is resolved fresh on every call (never cached) so family
/// switches and account changes always load the current `family_id`.
class NotesCubit extends Cubit<NotesState> {
  NotesCubit({
    required this.getNotesUsecase,
    required this.createNoteUsecase,
    required this.updateNoteUsecase,
    required this.deleteNoteUsecase,
    required this.peopleRepository,
    required this.authService,
    required this.isAtNoteLimitUsecase,
  }) : super(const NotesInitial());

  final GetNotesUsecase getNotesUsecase;
  final CreateNoteUsecase createNoteUsecase;
  final UpdateNoteUsecase updateNoteUsecase;
  final DeleteNoteUsecase deleteNoteUsecase;
  final PeopleRepository peopleRepository;
  final AuthService authService;
  final IsAtNoteLimitUsecase isAtNoteLimitUsecase;

  /// Display name of the current family for the list subtitle
  /// (`Shared with {family}`); `null` until loaded or when unavailable.
  String? _familyName;

  /// Display name of the current family for the list subtitle.
  String? get familyName => _familyName;

  /// Loads the family notes ordered `created_at DESC`.
  Future<void> loadNotes({String? familyId}) async {
    emit(const NotesLoading());
    final userId = authService.currentUserId;
    if (userId == null) {
      _familyName = null;
      emit(const NotesUnauthenticated());
      return;
    }
    final resolved = familyId ?? await _resolveFamilyId(userId);
    if (resolved == null) {
      _familyName = null;
      emit(const NotesLoaded([]));
      return;
    }
    await _loadFamilyName();
    final result = await getNotesUsecase(resolved);
    result.fold((err) => emit(NotesFailure(err.message)), (notes) {
      emit(NotesLoaded(notes));
    });
  }

  /// Creates a note, then reloads the list.
  ///
  /// Free-tier users are capped at 3 notes:
  /// hitting the cap emits [NotesLimitReached] (carrying the reloaded
  /// list so the list view keeps rendering) and the editor routes to the
  /// paywall instead. Paid users skip the check. Updates are never
  /// capped (only creation counts). Every path emits exactly one
  /// outcome state; unexpected errors map to a generic failure.
  Future<void> createNote({
    required String title,
    required String content,
    required String color,
  }) async {
    emit(const NotesLoading());
    try {
      final userId = authService.currentUserId;
      final familyId = userId == null ? null : await _resolveFamilyId(userId);
      if (familyId == null) {
        emit(const NotesFailure(notesFailureNoFamily));
        return;
      }
      if (await isAtFreeLimit(familyId: familyId)) {
        final result = await getNotesUsecase(familyId);
        result.fold(
          (_) => emit(const NotesFailure(notesFailureLimitReached)),
          (notes) => emit(NotesLimitReached(notes)),
        );
        return;
      }
      final now = DateTime.now().toUtc();
      final model = NoteModel(
        id: '',
        familyId: familyId,
        createdBy: userId ?? '',
        title: title,
        content: content,
        color: color,
        createdAt: now,
        updatedAt: now,
      );
      final result = await createNoteUsecase(model, familyId);
      await result.fold((err) async => emit(NotesFailure(err.message)), (
        _,
      ) async {
        emit(const NoteActionSuccess());
        await loadNotes(familyId: familyId);
      });
    } on Object catch (_) {
      emit(const NotesFailure(notesFailureUnknown));
    }
  }

  /// Updates a note (last-write-wins), then reloads the list.
  Future<void> updateNote({
    required NoteEntity note,
    required String title,
    required String content,
    required String color,
  }) async {
    emit(const NotesLoading());
    final model = NoteModel(
      id: note.id,
      familyId: note.familyId,
      createdBy: note.createdBy,
      title: title,
      content: content,
      color: color,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
    );
    final result = await updateNoteUsecase(model);
    await result.fold(
      (err) async {
        emit(NotesFailure(err.message));
        await loadNotes();
      },
      (_) async {
        emit(const NoteActionSuccess());
        await loadNotes();
      },
    );
  }

  /// Hard-deletes a note after confirm, then reloads the list.
  ///
  /// Dismissing the confirm dialog must re-emit the current [NotesLoaded]
  /// instead — callers simply skip calling this method on dismiss.
  Future<void> deleteNote(String id) async {
    emit(const NotesLoading());
    final result = await deleteNoteUsecase(id);
    await result.fold(
      (err) async {
        emit(NotesFailure(err.message));
        await loadNotes();
      },
      (_) async {
        emit(const NoteActionSuccess());
        await loadNotes();
      },
    );
  }

  /// Whether the current user belongs to a family.
  Future<bool> hasFamily() async {
    final userId = authService.currentUserId;
    if (userId == null) return false;
    try {
      return await _resolveFamilyId(userId) != null;
    } on Object catch (_) {
      return false;
    }
  }

  /// Whether a free-tier user has hit the notes cap.
  ///
  /// Views call this before opening the editor so capped users see the
  /// limit message (with an upgrade action) instead of a form they cannot
  /// save. Delegates to [IsAtNoteLimitUsecase] (paid check + count +
  /// free-tier caps); fail-open (`false`) on every error and the create
  /// path re-checks anyway. The whole body is guarded so no lookup
  /// failure ever throws to the view.
  Future<bool> isAtFreeLimit({String? familyId}) async {
    try {
      final userId = authService.currentUserId;
      if (userId == null) return false;
      final resolved = familyId ?? await _resolveFamilyId(userId);
      if (resolved == null) return false;
      return await isAtNoteLimitUsecase(familyId: resolved);
    } on Object catch (_) {
      return false;
    }
  }

  /// Resolves the current `family_id` fresh on every call — never cached —
  /// so family switches and account changes always load current data.
  Future<String?> _resolveFamilyId(String userId) async {
    try {
      final ids = await peopleRepository.getFamilyIdsForUser(userId);
      return ids.isEmpty ? null : ids.first;
    } on Object catch (_) {
      return null;
    }
  }

  /// Best-effort load of the family display name; stays `null` on failure.
  Future<void> _loadFamilyName() async {
    try {
      final result = await peopleRepository.getMyFamily();
      result.fold((_) => _familyName = null, (f) => _familyName = f.name);
    } on Object catch (_) {
      _familyName = null;
    }
  }
}
