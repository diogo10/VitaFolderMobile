/// Canonical note color allowlist (lowercase names stored in Supabase).
///
/// Pure-Dart domain file: no Flutter imports. `NoteEntity.from` returns
/// `null` for any value outside this set. The repository sends only the
/// name — never `Color.toString()` or hex. The Flutter `Color` palettes
/// live in `presentation/utils/note_color_palette.dart`.
const Set<String> noteColorAllowlist = {
  'yellow',
  'pink',
  'blue',
  'green',
  'orange',
};

/// Returns the allowlisted color name, or `null` when invalid.
String? noteColorFrom(String? value) {
  if (value == null) return null;
  return noteColorAllowlist.contains(value) ? value : null;
}
