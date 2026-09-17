import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/errors/failure.dart';

void main() {
  group('Failure', () {
    test('has a default message', () {
      expect(Failure().message, 'Unexpected error occurred.');
    });

    test('keeps a custom message', () {
      expect(Failure(message: 'boom').message, 'boom');
    });

    test('is an Exception', () {
      expect(Failure(), isA<Exception>());
    });
  });

  group('NoDataException', () {
    test('has a default message', () {
      expect(NoDataException().message, 'No data available.');
    });

    test('keeps a custom message', () {
      expect(NoDataException(message: 'empty').message, 'empty');
    });

    test('is an Exception', () {
      expect(NoDataException(), isA<Exception>());
    });
  });
}
