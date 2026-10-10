import 'package:flutter/material.dart';
import 'package:house_mira/features/notes/domain/entities/note_color.dart';

/// Flutter [Color] palettes keyed by [noteColorAllowlist] name.
///
/// Split out of the domain `note_color.dart` (ADR-0006: domain has zero
/// Flutter imports). Presentation-only; domain validation still lives in
/// `noteColorFrom`. Design asset:
/// `designs/html/01-FamilyAdmin - Notes.html`.

/// Card background tints, one per allowlisted name.
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
