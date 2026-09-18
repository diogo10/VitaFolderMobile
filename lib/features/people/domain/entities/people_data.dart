import 'package:house_mira/features/people/domain/entities/family_entity.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';

final class PeopleData {
  PeopleData({required this.family, required this.people});
  final FamilyEntity family;
  final List<PersonEntity> people;
}
