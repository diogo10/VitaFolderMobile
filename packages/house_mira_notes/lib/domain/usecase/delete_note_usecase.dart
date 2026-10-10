import 'package:fpdart/fpdart.dart';
import 'package:house_mira_core/errors/failure.dart';
import 'package:house_mira_notes/domain/repository/notes_repository.dart';

/// Thin pass-through: hard delete.
class DeleteNoteUsecase {
  DeleteNoteUsecase({required this.repository});
  final NotesRepository repository;

  Future<Either<Failure, bool>> call(String id) async {
    return repository.deleteNote(id);
  }
}
