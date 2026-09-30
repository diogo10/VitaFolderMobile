import 'package:flutter/material.dart';

/// Canonical note color allowlist (lowercase names stored in Supabase).
///
/// Single mapping site for the palette; `NoteEntity.from` returns `null`
/// for any value outside this set. The repository sends only the name —
/// never `Color.toString()` or hex.
const Set<String> noteColorAllowlist = {
  'yellow',
  'pink',
  'blue',
  'green',
  'orange',
};

/// Card background tints, one per allowlisted name (design asset:
/// `designs/html/01-FamilyAdmin - Notes.html`).
const Map<String, Color> noteColorPalette = {
  'yellow': Color(0xFFFFFBEB),
  'pink': Color(0xFFFFF1F2),
  'blue': Color(0xFFEFF6FF),
  'green': Color(0xFFF0FDF4),
  'orange': Color(0xFFFFF7ED),
};

/// Icon-tile backgrounds paired with [noteColorPalette].
const Map<String, Color> noteColorTilePalette = {
  'yellow': Color(0xFFFEF3C7),
  'pink': Color(0xFFFFE4E6),
  'blue': Color(0xFFDBEAFE),
  'green': Color(0xFFDCFCE7),
  'orange': Color(0xFFFFEDD5),
};

/// Icon foregrounds paired with [noteColorTilePalette].
const Map<String, Color> noteColorIconPalette = {
  'yellow': Color(0xFFD97706),
  'pink': Color(0xFFE11D48),
  'blue': Color(0xFF2563EB),
  'green': Color(0xFF16A34A),
  'orange': Color(0xFFEA580C),
};

/// Returns the allowlisted color name, or `null` when invalid.
String? noteColorFrom(String? value) {
  if (value == null) return null;
  return noteColorAllowlist.contains(value) ? value : null;
}
