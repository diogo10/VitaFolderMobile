import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/notes/domain/entities/note_color.dart';

void main() {
  group('note colors', () {
    test('allowlist has exactly the 5 frozen names', () {
      expect(noteColorAllowlist, {
        'yellow',
        'pink',
        'blue',
        'green',
        'orange',
      });
    });

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

    test('noteColorFrom returns name or null', () {
      expect(noteColorFrom('yellow'), 'yellow');
      expect(noteColorFrom('red'), isNull);
      expect(noteColorFrom('YELLOW'), isNull);
      expect(noteColorFrom(null), isNull);
      expect(noteColorFrom(''), isNull);
    });
  });
}
