import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/notes/data/models/note_model.dart';
import 'package:house_mira/features/notes/domain/repository/notes_repository.dart';

/// Thin pass-through: creates a note, returns the new row id.
class CreateNoteUsecase {
  CreateNoteUsecase({required this.repository});
  final NotesRepository repository;

  Future<Either<Failure, String>> call(
    NoteModel note,
    String familyId,
  ) async {
    return repository.createNote(note, familyId);
  }
}
