/// Public API for `house_mira_people`.
///
/// Domain entities, repository contracts, and use cases only.
/// Data implementations and presentation stay package-private
/// except through the feature's service locator and router wiring.
export 'domain/entities/family_entity.dart';
export 'domain/entities/people_data.dart';
export 'domain/entities/person_entity.dart';
export 'domain/invite_code.dart';
export 'domain/repository/people_repository.dart';
export 'domain/usecase/create_family_usecase.dart';
export 'domain/usecase/delete_family_usecase.dart';
export 'domain/usecase/get_my_family_id_usecase.dart';
export 'domain/usecase/get_people_usecase.dart';
export 'domain/usecase/join_family_usecase.dart';
export 'domain/usecase/remove_member_usecase.dart';
export 'domain/usecase/update_family_name_usecase.dart';
export 'people_service_locator.dart';
