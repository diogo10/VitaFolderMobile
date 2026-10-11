import 'package:house_mira_notes/domain/entities/note_color.dart';
import 'package:meta/meta.dart';

/// Immutable family note entity.
///
/// `NoteEntity.from` returns `null` on ANY violation (missing/invalid ids,
/// empty-after-trim or over-limit title/content, non-allowlisted color,
/// bad timestamps). Explicit failure beats wrong data — never fall back
/// to defaults.
@immutable
class NoteEntity {
  const NoteEntity({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.title,
    required this.content,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Maximum trimmed lengths (mirror the DB CHECKs).
  static const int maxTitleLength = 100;
  static const int maxContentLength = 300;

  final String id;
  final String familyId;
  final String createdBy;
  final String title;
  final String content;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Parses a Supabase row; `null` on any violation.
  static NoteEntity? from(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    final rawId = json['id']?.toString() ?? '';
    final rawFamilyId = json['family_id']?.toString() ?? '';
    final rawCreatedBy = json['created_by']?.toString() ?? '';
    final rawTitle = json['title'];
    final rawContent = json['content'];
    final rawColor = json['color']?.toString();
    if (rawId.isEmpty) return null;
    if (rawFamilyId.isEmpty) return null;
    if (rawCreatedBy.isEmpty) return null;
    if (rawTitle is! String) return null;
    if (rawContent is! String) return null;
    final title = rawTitle.trim();
    final content = rawContent.trim();
    if (title.isEmpty || title.length > maxTitleLength) return null;
    if (content.isEmpty || content.length > maxContentLength) return null;
    if (noteColorFrom(rawColor) == null) return null;
    final createdAt = DateTime.tryParse(
      json['created_at']?.toString() ?? '',
    );
    final updatedAt = DateTime.tryParse(
      json['updated_at']?.toString() ?? '',
    );
    if (createdAt == null || updatedAt == null) return null;
    return NoteEntity(
      id: rawId,
      familyId: rawFamilyId,
      createdBy: rawCreatedBy,
      title: rawTitle,
      content: rawContent,
      color: rawColor!,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  NoteEntity copyWith({
    String? id,
    String? familyId,
    String? createdBy,
    String? title,
    String? content,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    // NOTE: written as an explicit null-check (not `??`) because the VM
    // attributes `title ?? this.title` to no source line, which trips the
    // 100% line-coverage gate. Do not simplify without re-running coverage.
    var resolvedTitle = this.title;
    if (title != null) {
      resolvedTitle = title;
    }
    return NoteEntity(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      createdBy: createdBy ?? this.createdBy,
      title: resolvedTitle,
      content: content ?? this.content,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NoteEntity) return false;
    return id == other.id &&
        familyId == other.familyId &&
        createdBy == other.createdBy &&
        title == other.title &&
        content == other.content &&
        color == other.color &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    familyId,
    createdBy,
    title,
    content,
    color,
    createdAt,
    updatedAt,
  );
}
