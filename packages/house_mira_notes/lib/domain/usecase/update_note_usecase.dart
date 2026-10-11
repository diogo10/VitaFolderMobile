import 'package:fpdart/fpdart.dart';
import 'package:house_mira_core/errors/failure.dart';
import 'package:house_mira_notes/data/models/note_model.dart';
import 'package:house_mira_notes/domain/repository/notes_repository.dart';

/// Thin pass-through: last-write-wins update.
class UpdateNoteUsecase {
  UpdateNoteUsecase({required this.repository});
  final NotesRepository repository;

  Future<Either<Failure, bool>> call(NoteModel note) async {
    return repository.updateNote(note);
  }
}
