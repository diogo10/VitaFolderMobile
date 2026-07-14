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

class PeopleLoaded extends PeopleState {
  List<PersonEntity> people;
  PeopleLoaded({required this.people});
}

class PeopleError extends PeopleState {
  PeopleError();
}
