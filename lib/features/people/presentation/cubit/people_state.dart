import 'package:vita_folder_mobile/features/people/domain/entities/person_entity.dart';

sealed class PeopleState {
  PeopleState();
}

class PeopleInitial extends PeopleState {
  PeopleInitial();
}

class PeopleLoading extends PeopleState {
  PeopleLoading();
}

class PeopleEmpty extends PeopleState {
  PeopleEmpty();
}

class PeopleLoaded extends PeopleState {
  List<PersonEntity> people;
  String inviteCode;
  String familyName;
  PeopleLoaded({required this.people, required this.inviteCode, required this.familyName});
}

class PeopleError extends PeopleState {
  PeopleError();
}
