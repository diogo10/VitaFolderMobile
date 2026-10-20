import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira_core/theme/app_constants.dart';
import 'package:house_mira_core/theme/app_theme.dart';

/// Guards the release-build font crash.
///
/// The theme used to resolve Figtree through `google_fonts`, which downloads
/// the font file at runtime. Release builds disable that download, so the font
/// had to be bundled; when it was missing the app crashed on startup with
/// "GoogleFonts.config.allowRuntimeFetching is false, but the font
/// Figtree-Regular was not found in the application assets".
///
/// The fonts now ship inside the bundle, so every family the app renders with
/// must be declared in the app `pubspec.yaml` with a readable asset file that
/// really carries the declared family and weight.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<List<Map<String, dynamic>>> fontFamily(String family) async {
    final manifest =
        json.decode(await rootBundle.loadString('FontManifest.json'))
            as List<dynamic>;
    final families = manifest.cast<Map<String, dynamic>>();
    final matches = families
        .where((entry) => entry['family'] == family)
        .toList();
    expect(
      matches,
      hasLength(1),
      reason: 'The $family family must be declared in the app pubspec.yaml',
    );
    return (matches.single['fonts'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  Future<void> expectBundled(String family) async {
    final fonts = await fontFamily(family);
    expect(fonts, isNotEmpty, reason: '$family must ship at least one file');

    for (final font in fonts) {
      final asset = font['asset'] as String;
      final bytes = await rootBundle.load(asset);
      expect(
        bytes.lengthInBytes,
        greaterThan(0),
        reason: '$asset must be part of the bundle',
      );
    }
  }

  group('bundled fonts', () {
    test('Figtree ships with the bundle', () async {
      await expectBundled(AppConstants.fontFamily);
    });

    test('Outfit ships with the bundle', () async {
      await expectBundled('Outfit');
    });

    test('declared weights match the bundled font files', () async {
      for (final family in [AppConstants.fontFamily, 'Outfit']) {
        for (final font in await fontFamily(family)) {
          final asset = font['asset'] as String;
          final declaredWeight = font['weight'] as int?;
          if (declaredWeight == null) {
            continue;
          }

          final fontFile = _TrueTypeFont(await rootBundle.load(asset));
          expect(
            fontFile.weightClass,
            declaredWeight,
            reason: '$asset must be declared with the weight it carries',
          );
          expect(
            fontFile.familyNames,
            contains(family),
            reason: '$asset must belong to the $family family',
          );
        }
      }
    });
  });

  group('AppTheme fonts', () {
    test('every text style uses the bundled Figtree family', () {
      final textTheme = AppTheme.lightTheme.textTheme;
      final styles = <TextStyle?>[
        textTheme.displayLarge,
        textTheme.displayMedium,
        textTheme.displaySmall,
        textTheme.headlineLarge,
        textTheme.headlineMedium,
        textTheme.headlineSmall,
        textTheme.titleLarge,
        textTheme.titleMedium,
        textTheme.titleSmall,
        textTheme.labelLarge,
        textTheme.labelMedium,
        textTheme.labelSmall,
        textTheme.bodyLarge,
        textTheme.bodyMedium,
        textTheme.bodySmall,
      ];

      for (final style in styles) {
        expect(
          style?.fontFamily,
          AppConstants.fontFamily,
          reason: 'Text styles must not rely on a runtime font download',
        );
      }
    });

    test('the dark theme uses the same family', () {
      expect(
        AppTheme.darkTheme.textTheme.bodyMedium?.fontFamily,
        AppConstants.fontFamily,
      );
    });
  });
}

/// Minimal TrueType reader: exposes the OS/2 weight class and the family
/// names of a font file so the test can prove that the declared family and
/// weight match the bundled binary.
class _TrueTypeFont {
  _TrueTypeFont(this._data);

  final ByteData _data;

  Uint8List get _bytes =>
      _data.buffer.asUint8List(_data.offsetInBytes, _data.lengthInBytes);

  int _u16(int offset) => _data.getUint16(offset);

  int _u32(int offset) => _data.getUint32(offset);

  String _tag(int offset) =>
      String.fromCharCodes(_bytes.sublist(offset, offset + 4));

  Map<String, ({int offset, int length})> get _tables {
    final tables = <String, ({int offset, int length})>{};
    final count = _u16(4);
    for (var i = 0; i < count; i++) {
      final record = 12 + i * 16;
      tables[_tag(record)] = (
        offset: _u32(record + 8),
        length: _u32(record + 12),
      );
    }
    return tables;
  }

  /// The `usWeightClass` value of the OS/2 table.
  int get weightClass {
    final table = _tables['OS/2'];
    expect(table, isNotNull, reason: 'Font file has no OS/2 table');
    return _u16(table!.offset + 4);
  }

  /// The family names of the `name` table (name IDs 1 and 16).
  Set<String> get familyNames {
    final table = _tables['name'];
    expect(table, isNotNull, reason: 'Font file has no name table');
    final base = table!.offset;
    final count = _u16(base + 2);
    final stringsBase = base + _u16(base + 4);
    final names = <String>{};

    for (var i = 0; i < count; i++) {
      final record = base + 6 + i * 12;
      final nameId = _u16(record + 6);
      if (nameId != 1 && nameId != 16) {
        continue;
      }
      final platformId = _u16(record);
      final length = _u16(record + 8);
      final offset = _u16(record + 10);
      final start = stringsBase + offset;
      names.add(
        platformId == 3
            ? _decodeUtf16(start, length)
            : String.fromCharCodes(_bytes.sublist(start, start + length)),
      );
    }

    return names;
  }

  String _decodeUtf16(int start, int length) {
    final units = List<int>.generate(length ~/ 2, (i) => _u16(start + i * 2));
    return String.fromCharCodes(units);
  }
}
