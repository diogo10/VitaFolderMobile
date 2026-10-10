import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/notes/domain/entities/note_color.dart';

void main() {
  group('note colors', () {
    test('allowlist has exactly the 5 frozen names', () {
      expect(noteColorAllowlist, {'yellow', 'pink', 'blue', 'green', 'orange'});
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
