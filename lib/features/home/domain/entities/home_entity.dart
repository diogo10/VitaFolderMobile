import 'package:collection/collection.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/person_entity.dart';

class HomeEntity {
  final List<PersonEntity> peopleInCircle;
  final bool hasReminders;

  HomeEntity({required this.peopleInCircle, this.hasReminders = false});

  HomeEntity copyWith({
    List<PersonEntity>? peopleInCircle,
    bool? hasReminders,
  }) {
    return HomeEntity(
      peopleInCircle: peopleInCircle ?? this.peopleInCircle,
      hasReminders: hasReminders ?? this.hasReminders,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HomeEntity) return false;
    return const DeepCollectionEquality().equals(
          peopleInCircle,
          other.peopleInCircle,
        ) &&
        hasReminders == other.hasReminders;
  }

  @override
  int get hashCode => Object.hash(
    const DeepCollectionEquality().hash(peopleInCircle),
    hasReminders,
  );
}
