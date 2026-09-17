import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/network/dio_client.dart';

void main() {
  group('DioClient', () {
    test('creates a client with the expected base configuration', () {
      final dio = DioClient.instance();

      expect(dio.options.baseUrl, 'https://jsonplaceholder.typicode.com');
      expect(dio.options.connectTimeout, const Duration(seconds: 10));
      expect(dio.options.receiveTimeout, const Duration(seconds: 10));
    });

    test('creates a new instance on each call', () {
      expect(DioClient.instance(), isNot(same(DioClient.instance())));
    });
  });
}
