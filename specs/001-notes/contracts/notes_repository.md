# Contract: NotesRepository (Dart)

**Spec**: [../spec.md](../spec.md) | **Data model**: [../data-model.md](../data-model.md)

Interface: `lib/features/notes/domain/repository/notes_repository.dart`. All methods return `Future<Either<Failure, T>>` (FR-103). Errors mapped to `Failure` at `NotesRepositoryImpl` boundary (`on Failure` → message passthrough, `on Object` → generic `Failure()`); no Supabase types leak past the boundary.

```dart
abstract interface class NotesRepository {
  /// List scoped to one family, ordered created_at DESC.
  Future<Either<Failure, List<NoteEntity>>> getNotes(String familyId);

  /// Returns created row id.
  Future<Either<Failure, String>> createNote(NoteModel note, String familyId);

  /// Last-write-wins. Returns true on success; stale/missing row -> Left(Failure not-found).
  Future<Either<Failure, bool>> updateNote(NoteModel note);

  /// Hard delete. Returns true on success; stale/missing row -> Left(Failure not-found).
  Future<Either<Failure, bool>> deleteNote(String id);
}
```

Use-cases (1:1, thin): `GetNotesUsecase(repository).call(familyId)`, `CreateNoteUsecase(repository).call(note, familyId)`, `UpdateNoteUsecase(repository).call(note)`, `DeleteNoteUsecase(repository).call(id)`.

`NotesCubit` surface (FR-102): `loadNotes({String? familyId})`, `createNote({title, content, color})`, `updateNote({note, title, content, color})`, `deleteNote(id)` — each emits `NotesLoading` first then exactly one outcome; mutations emit `NoteActionSuccess` then reload to `NotesLoaded`.
