import 'package:fpdart/fpdart.dart';
import 'package:house_mira_core/errors/failure.dart';
import 'package:house_mira_notes/domain/entities/note_entity.dart';
import 'package:house_mira_notes/domain/repository/notes_repository.dart';
import 'package:house_mira_people/domain/repository/people_repository.dart';

/// Lists family notes ordered `created_at DESC`, resolving creator ids to
/// family display names (same as `GetReminderUsecase`). Unknown creators
/// keep their raw id instead of a fallback name.
class GetNotesUsecase {
  GetNotesUsecase({required this.repository, required this.peopleRepository});
  final NotesRepository repository;
  final PeopleRepository peopleRepository;

  Future<Either<Failure, List<NoteEntity>>> call(String familyId) async {
    final notesResult = await repository.getNotes(familyId);
    return notesResult.fold((err) => Left(Failure(message: err.message)), (
      notes,
    ) async {
      try {
        final people = await peopleRepository.getProfilesWithRoleForFamily(
          familyId,
        );
        final peopleById = {
          for (final person in people)
            if (person.id != null) person.id!: person,
        };
        return Right(
          notes.map((note) {
            final person = peopleById[note.createdBy];
            if (person == null) return note;
            return note.copyWith(createdBy: person.name ?? note.createdBy);
          }).toList(),
        );
      } on Object catch (error) {
        // Same crash class as `GetReminderUsecase`: the people lookup throws
        // on a backend/transport failure, and an exception escaping this fold
        // callback is an unhandled async error (FATAL). Report a failure
        // instead so the notes screen shows its error state.
        return Left(Failure(message: error.toString()));
      }
    });
  }
}
