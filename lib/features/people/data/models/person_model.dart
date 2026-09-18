import 'dart:convert';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';

class PersonModel extends PersonEntity {
  const PersonModel({
    required String id,
    required String name,
    required String email,
    required String phone,
  }) : super(id: id, name: name, email: email, phone: phone);

  factory PersonModel.fromMap(Map<String, dynamic> map) {
    return PersonModel(
      id: map['id'].toString(),
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
    );
  }

  factory PersonModel.fromJson(String source) =>
      PersonModel.fromMap(json.decode(source) as Map<String, dynamic>);

  Map<String, dynamic> toMap() {
    return {
      'id': id ?? '',
      'name': name ?? '',
      'email': email ?? '',
      'phone': phone ?? '',
    };
  }

  String toJson() => json.encode(toMap());
}
