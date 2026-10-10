import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira_people/domain/invite_code.dart';

void main() {
  group('normalizeInviteCode', () {
    test('returns canonical code unchanged', () {
      expect(normalizeInviteCode('ABC123'), 'ABC123');
    });

    test('trims surrounding whitespace', () {
      expect(normalizeInviteCode('  ABC123\n'), 'ABC123');
    });

    test('uppercases lowercase input', () {
      expect(normalizeInviteCode('abc123'), 'ABC123');
    });

    test('strips dashes, underscores and inner spaces', () {
      expect(normalizeInviteCode('ab-12 34'), 'AB1234');
      expect(normalizeInviteCode('AB_1234'), 'AB1234');
    });

    test('returns empty for blank input', () {
      expect(normalizeInviteCode('   '), isEmpty);
    });
  });

  group('isValidInviteCode', () {
    test('accepts six uppercase alphanumerics', () {
      expect(isValidInviteCode('ABC123'), isTrue);
      expect(isValidInviteCode('000000'), isTrue);
    });

    test('rejects empty, short, long and non-alphanumeric codes', () {
      expect(isValidInviteCode(''), isFalse);
      expect(isValidInviteCode('ABC12'), isFalse);
      expect(isValidInviteCode('ABC1234'), isFalse);
      expect(isValidInviteCode('AB-123'), isFalse);
      expect(isValidInviteCode('ab1234'), isFalse);
      expect(isValidInviteCode('ABC 23'), isFalse);
    });
  });
}
