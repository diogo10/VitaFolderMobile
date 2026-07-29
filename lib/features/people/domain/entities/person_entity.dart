class PersonEntity {
  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? role;

  PersonEntity({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.role
  });

  PersonEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
  }) {
    return PersonEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role
    );
  }

  static PersonEntity? from(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    return PersonEntity(
      id: json['id'] as String?,
      name: json['full_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String?,
    );
  }
}
