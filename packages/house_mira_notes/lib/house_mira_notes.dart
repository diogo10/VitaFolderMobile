/// Public API for `house_mira_notes`.
///
/// Domain entities, repository contracts, and use cases only.
/// Data implementations and presentation stay package-private
/// except through the feature's service locator and router wiring.
export 'domain/entities/note_color.dart';
export 'domain/entities/note_entity.dart';
export 'domain/repository/notes_repository.dart';
export 'domain/usecase/create_note_usecase.dart';
export 'domain/usecase/delete_note_usecase.dart';
export 'domain/usecase/get_notes_usecase.dart';
export 'domain/usecase/update_note_usecase.dart';
export 'application/is_at_note_limit_usecase.dart';
export 'notes_service_locator.dart';
