import 'dart:convert';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';

class ReminderModel extends ReminderEntity {
  ReminderModel({required super.title, required super.body, required super.id});

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'id': id,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      title: map['title'] as String,
      body: map['body'] as String,
      id: map['id'] is int ? map['id'] : int.parse(map['id'].toString()),
    );
  }

  String toJson() => json.encode(toMap());

  factory ReminderModel.fromJson(String source) =>
      ReminderModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
