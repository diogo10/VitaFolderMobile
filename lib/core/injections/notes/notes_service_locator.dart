import 'package:get_it/get_it.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/features/notes/data/repository/notes_repository_impl.dart';
import 'package:house_mira/features/notes/domain/repository/notes_repository.dart';
import 'package:house_mira/features/notes/domain/usecase/create_note_usecase.dart';
import 'package:house_mira/features/notes/domain/usecase/delete_note_usecase.dart';
import 'package:house_mira/features/notes/domain/usecase/get_notes_usecase.dart';
import 'package:house_mira/features/notes/domain/usecase/update_note_usecase.dart';
import 'package:house_mira/features/notes/presentation/cubit/notes_cubit.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';

/// GetIt graph for the Notes feature, aggregated in `service_locator.dart`.
class NotesServiceLocator {
  NotesServiceLocator(this.sl);
  final GetIt sl;

  void init() {
    sl
      ..registerSingleton<NotesRepository>(
        NotesRepositoryImpl(),
        instanceName: 'notesRepositoryImpl',
      )
      ..registerSingleton<GetNotesUsecase>(
        GetNotesUsecase(
          repository: sl(instanceName: 'notesRepositoryImpl'),
          peopleRepository: sl<PeopleRepository>(
            instanceName: 'peopleRepositoryImpl',
          ),
        ),
        instanceName: 'getNotesUsecase',
      )
      ..registerSingleton<CreateNoteUsecase>(
        CreateNoteUsecase(
          repository: sl(instanceName: 'notesRepositoryImpl'),
        ),
        instanceName: 'createNoteUsecase',
      )
      ..registerSingleton<UpdateNoteUsecase>(
        UpdateNoteUsecase(
          repository: sl(instanceName: 'notesRepositoryImpl'),
        ),
        instanceName: 'updateNoteUsecase',
      )
      ..registerSingleton<DeleteNoteUsecase>(
        DeleteNoteUsecase(
          repository: sl(instanceName: 'notesRepositoryImpl'),
        ),
        instanceName: 'deleteNoteUsecase',
      )
      // Tab cubit stays a shared lazy singleton (see createRouter factory
      // contract). The editor screen reuses its methods (single-cubit
      // requirement FR-102), so no one-shot cubit is registered here.
      ..registerLazySingleton<NotesCubit>(
        () => NotesCubit(
          getNotesUsecase: sl(instanceName: 'getNotesUsecase'),
          createNoteUsecase: sl(instanceName: 'createNoteUsecase'),
          updateNoteUsecase: sl(instanceName: 'updateNoteUsecase'),
          deleteNoteUsecase: sl(instanceName: 'deleteNoteUsecase'),
          peopleRepository: sl<PeopleRepository>(
            instanceName: 'peopleRepositoryImpl',
          ),
          authService: sl<AuthService>(instanceName: 'authService'),
        ),
        instanceName: 'notesCubit',
      );
  }
}
