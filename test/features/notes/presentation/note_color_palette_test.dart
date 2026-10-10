import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/notes/domain/entities/note_color.dart';
import 'package:house_mira/features/notes/presentation/utils/note_color_palette.dart';

void main() {
  group('note color palettes', () {
    test('palettes have one entry per allowlisted name', () {
      expect(noteColorPalette.keys.toSet(), noteColorAllowlist);
      expect(noteColorTilePalette.keys.toSet(), noteColorAllowlist);
      expect(noteColorIconPalette.keys.toSet(), noteColorAllowlist);
      for (final color in [
        ...noteColorPalette.values,
        ...noteColorTilePalette.values,
        ...noteColorIconPalette.values,
      ]) {
        expect(color, isA<Color>());
      }
    });
  });
}
