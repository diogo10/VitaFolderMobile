import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira_account/presentation/views/support_screen.dart';
import 'package:house_mira_core/router/app_routes.dart';

void main() {
  group('SupportScreen', () {
    test('defaults to the support website URL', () {
      expect(
        const SupportScreen().url,
        'https://housemira.com/support',
      );
      expect(AppRoutes.supportUrl, 'https://housemira.com/support');
    });

    test('exposes the support route location', () {
      expect(AppRoutes.support, '/support');
    });
  });
}
