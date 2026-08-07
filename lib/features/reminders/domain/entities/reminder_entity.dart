import 'reminder_type.dart';

class ReminderEntity {
  final String title;
  final String body;
  final String id;
  final ReminderType type;
  final String dueDate;
  final String repeatRule;
  final String status;
  final String createdBy;
  final String createdAt;

ReminderEntity({
    required this.title,
    required this.body,
    required this.id,
    required this.type,
    required this.dueDate,
    required this.repeatRule,
    required this.status,
    required this.createdBy,
    required this.createdAt,
  });

  ReminderEntity copyWith({
    String? title,
    String? body,
    String? id,
    ReminderType? type,
    String? dueDate,
    String? repeatRule,
    String? status,
    String? createdBy,
    String? createdAt,
  }) {
    return ReminderEntity(
      title: title ?? this.title,
      body: body ?? this.body,
      id: id ?? this.id,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      repeatRule: repeatRule ?? this.repeatRule,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
