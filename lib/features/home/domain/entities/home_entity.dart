import 'package:collection/collection.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';

class HomeEntity {
  final List<PersonEntity> peopleInCircle;
  final bool hasReminders;
  final String familyName;
  final String myRole;
  final int activeMembers;
  final List<ReminderEntity> reminders;

  HomeEntity({
    required this.peopleInCircle,
    this.hasReminders = false,
    this.familyName = '',
    this.myRole = '',
    this.activeMembers = 0,
    this.reminders = const [],
  });

  HomeEntity copyWith({
    List<PersonEntity>? peopleInCircle,
    bool? hasReminders,
    String? familyName,
    String? myRole,
    int? activeMembers,
    List<ReminderEntity>? reminders,
  }) {
    return HomeEntity(
      peopleInCircle: peopleInCircle ?? this.peopleInCircle,
      hasReminders: hasReminders ?? this.hasReminders,
      familyName: familyName ?? this.familyName,
      myRole: myRole ?? this.myRole,
      activeMembers: activeMembers ?? this.activeMembers,
      reminders: reminders ?? this.reminders,
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
        hasReminders == other.hasReminders &&
        familyName == other.familyName &&
        myRole == other.myRole &&
        activeMembers == other.activeMembers &&
        const DeepCollectionEquality().equals(reminders, other.reminders);
  }

  @override
  int get hashCode => Object.hash(
    const DeepCollectionEquality().hash(peopleInCircle),
    hasReminders,
    familyName,
    myRole,
    activeMembers,
    const DeepCollectionEquality().hash(reminders),
  );
}
