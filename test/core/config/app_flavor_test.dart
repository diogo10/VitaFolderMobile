import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/config/app_flavor.dart';

void main() {
  group('parseAppFlavor', () {
    test('parses each valid flavor', () {
      expect(parseAppFlavor('dev'), AppFlavor.dev);
      expect(parseAppFlavor('staging'), AppFlavor.staging);
      expect(parseAppFlavor('prod'), AppFlavor.prod);
    });

    test('is case-insensitive and trims whitespace', () {
      expect(parseAppFlavor('DEV'), AppFlavor.dev);
      expect(parseAppFlavor('  Staging  '), AppFlavor.staging);
      expect(parseAppFlavor('Prod'), AppFlavor.prod);
    });

    test('returns null for empty or unknown values', () {
      expect(parseAppFlavor(''), isNull);
      expect(parseAppFlavor('   '), isNull);
      expect(parseAppFlavor('production'), isNull);
      expect(parseAppFlavor('local'), isNull);
    });
  });
}
