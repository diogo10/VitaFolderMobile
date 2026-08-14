import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';

class ReminderModel extends ReminderEntity {
  ReminderModel({
    required super.title,
    required super.body,
    required super.id,
    required super.type,
    required super.dueDate,
    required super.repeatRule,
    required super.status,
    required super.createdBy,
    required super.createdAt,
  });

  static String _formatDueDateToDisplay(String rawDueDate) {
    final value = rawDueDate.trim();
    if (value.isEmpty) return '';

    final alreadyFormatted = DateFormat('dd/MM/yyyy HH:mm').tryParse(value);
    if (alreadyFormatted != null) return value;

    final parsedDate = DateTime.tryParse(value);
    if (parsedDate == null) return value;

    return DateFormat('dd/MM/yyyy HH:mm').format(parsedDate);
  }

  Map<String, dynamic> toCreate(String familyId) {
    return {
      'title': title,
      'type': type.value,
      'body': body,
      'due_at': dueDate.isEmpty ? null : dueDate,
      'repeat_rule': repeatRule,
      'status': status,
      'family_id': familyId,
      'created_by': createdBy,
      'created_at': createdAt,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    final rawDueDate = map['due_at'];

    return ReminderModel(
      title: map['title'] as String,
      body: map.containsKey('body') ? map['body'] as String : '',
      id: map['id'] is String ? map['id'] : int.parse(map['id'].toString()),
      type: ReminderType.fromString(map['type'] as String?) ?? (throw FormatException('Invalid reminder type')),
      dueDate: rawDueDate == null ? '' : _formatDueDateToDisplay(rawDueDate.toString()),
      repeatRule: map['repeat_rule']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      createdBy: map['created_by']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
    );
  }

  String toJson() => json.encode(toCreate(''));

  factory ReminderModel.fromJson(String source) =>
      ReminderModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
