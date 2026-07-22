import 'family_entity.dart';
import 'person_entity.dart';
final class PeopleData {
  final FamilyEntity family;
  final List<PersonEntity> people;

  PeopleData({required this.family, required this.people});
}