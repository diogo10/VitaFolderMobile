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
}
