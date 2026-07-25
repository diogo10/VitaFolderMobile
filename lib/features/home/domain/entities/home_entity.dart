import 'package:vita_folder_mobile/features/people/domain/entities/person_entity.dart';

class HomeEntity {
  final String greeting;
  final String date;
  final String message;
  final List<PersonEntity> peopleInCircle;

  HomeEntity({
    required this.greeting,
    required this.date,
    required this.message,
    required this.peopleInCircle,
  });

  HomeEntity copyWith({
    String? greeting,
    String? date,
    String? message,
    List<PersonEntity>? peopleInCircle,
  }) {
    return HomeEntity(
      greeting: greeting ?? this.greeting,
      date: date ?? this.date,
      message: message ?? this.message,
      peopleInCircle: peopleInCircle ?? this.peopleInCircle,
    );
  }
}
