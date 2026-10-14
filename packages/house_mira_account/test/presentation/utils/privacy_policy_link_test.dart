import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira_account/presentation/utils/privacy_policy_link.dart';

void main() {
  test('privacyPolicyUri points at housemira.com/privacy', () {
    expect(
      privacyPolicyUri,
      Uri(scheme: 'https', host: 'housemira.com', path: 'privacy'),
    );
    expect(privacyPolicyUri.toString(), 'https://housemira.com/privacy');
  });
}
