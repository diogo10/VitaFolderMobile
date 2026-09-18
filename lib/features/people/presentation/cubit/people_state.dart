import 'package:house_mira/features/people/domain/entities/person_entity.dart';

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

class PeopleInvalidFamilyCode extends PeopleState {
  PeopleInvalidFamilyCode();
}

class PeopleLoaded extends PeopleState {
  PeopleLoaded({
    required this.people,
    required this.inviteCode,
    required this.familyName,
  });
  List<PersonEntity> people;
  String inviteCode;
  String familyName;
}

class PeopleError extends PeopleState {
  PeopleError();
}
