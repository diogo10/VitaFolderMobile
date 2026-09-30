import 'package:fpdart/fpdart.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/notes/domain/entities/note_entity.dart';
import 'package:house_mira/features/notes/domain/repository/notes_repository.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';

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
    });
  }
}
