import 'package:house_mira_notes/domain/entities/note_entity.dart';

/// Extends the entity with Supabase row mapping.
///
/// `fromMap` delegates to [NoteEntity.from] and throws
/// [FormatException] on invalid rows so repository list parsing can
/// drop nulls explicitly. `toCreate`/`toUpdate` send only the color
/// name — never `Color.toString()` or hex.
class NoteModel extends NoteEntity {
  const NoteModel({
    required super.id,
    required super.familyId,
    required super.createdBy,
    required super.title,
    required super.content,
    required super.color,
    required super.createdAt,
    required super.updatedAt,
  });

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    final entity = NoteEntity.from(map);
    if (entity == null) {
      throw const FormatException('Invalid note row');
    }
    return NoteModel(
      id: entity.id,
      familyId: entity.familyId,
      createdBy: entity.createdBy,
      title: entity.title,
      content: entity.content,
      color: entity.color,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Payload for `INSERT` (relies on `created_by` default server-side).
  Map<String, dynamic> toCreate(String familyId) {
    return {
      'title': title,
      'content': content,
      'color': color,
      'family_id': familyId,
    };
  }

  /// Payload for `UPDATE` (last-write-wins; no version column).
  Map<String, dynamic> toUpdate() {
    return {'title': title, 'content': content, 'color': color};
  }
}
