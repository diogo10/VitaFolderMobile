import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/notes/domain/repository/notes_repository.dart';

/// Thin pass-through: hard delete.
class DeleteNoteUsecase {
  DeleteNoteUsecase({required this.repository});
  final NotesRepository repository;

  Future<Either<Failure, bool>> call(String id) async {
    return repository.deleteNote(id);
  }
}
