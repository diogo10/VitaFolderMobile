import 'package:flutter/material.dart';
import 'package:house_mira_notes/domain/entities/note_entity.dart';
import 'package:house_mira_notes/presentation/utils/note_color_palette.dart';
import 'package:house_mira_notes/presentation/utils/note_time_ago.dart';
import 'package:house_mira_core/theme/sand_palette.dart';

/// Renders the lightweight markdown subset (`**bold**`, `- ` list lines).
///
/// Plain text passes through unchanged. Used by [NoteCardWidget] so the
/// view and the stored raw string stay consistent (300-char limit counts
/// the raw string including markers).
class NoteMarkdownText extends StatelessWidget {
  const NoteMarkdownText({required this.content, super.key, this.style});
  final String content;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontSize: 12,
      color: SandPalette.sand600,
      height: 1.5,
    );
    final effective = base.merge(style);
    final lines = content.split('\n');
    final spans = <InlineSpan>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('- ')) {
        spans.add(TextSpan(text: '• ${line.substring(2)}', style: effective));
      } else {
        spans.addAll(_boldSpans(line, effective));
      }
      if (i != lines.length - 1) spans.add(const TextSpan(text: '\n'));
    }
    return Text.rich(TextSpan(children: spans), softWrap: true);
  }

  List<InlineSpan> _boldSpans(String line, TextStyle base) {
    final out = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    var cursor = 0;
    for (final match in pattern.allMatches(line)) {
      if (match.start > cursor) {
        out.add(
          TextSpan(text: line.substring(cursor, match.start), style: base),
        );
      }
      out.add(
        TextSpan(
          text: match.group(1),
          style: base.copyWith(fontWeight: FontWeight.w700),
        ),
      );
      cursor = match.end;
    }
    if (cursor < line.length) {
      out.add(TextSpan(text: line.substring(cursor), style: base));
    }
    if (out.isEmpty) out.add(TextSpan(text: line, style: base));
    return out;
  }
}

/// Family note card per `designs/html/01-FamilyAdmin - Notes.html`:
/// palette background, icon tile + relative timestamp, title
/// (max 2 lines, ellipsize), full markdown body (wraps), author row.
/// Tap opens the Edit/Remove bottom sheet.
class NoteCardWidget extends StatelessWidget {
  const NoteCardWidget({required this.note, required this.onTap, super.key});
  final NoteEntity note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = noteColorPalette[note.color] ?? Colors.white;
    final tile = noteColorTilePalette[note.color] ?? SandPalette.sand100;
    final iconColor = noteColorIconPalette[note.color] ?? SandPalette.sand500;
    final isFresh =
        DateTime.now().toUtc().difference(note.createdAt.toUtc()).inHours < 1;
    final author = note.createdBy;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: SandPalette.sand100),
      ),
      color: background,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: SandPalette.sand500.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: tile,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.sticky_note_2_rounded,
                        size: 22,
                        color: iconColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        formatNoteTimeAgo(context, note.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isFresh
                              ? const Color(0xFFD97706)
                              : SandPalette.sand400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                note.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: SandPalette.sand700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              NoteMarkdownText(content: note.content),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: SandPalette.sand200,
                    child: Text(
                      author.isNotEmpty ? author[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: SandPalette.sand600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: SandPalette.sand400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
