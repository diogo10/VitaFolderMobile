import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the iOS Universal Link wiring for family invites
/// (`https://vitafolder.app/invite/<code>`, handled in-app by the
/// `/invite/:code` route). Without the Associated Domain entitlement the OS
/// opens the link in Safari instead of the app.
void main() {
  const entitlementsPath = 'ios/Runner/Runner.entitlements';
  const projectPath = 'ios/Runner.xcodeproj/project.pbxproj';

  test('declares the invite Associated Domain', () {
    final entitlements = File(entitlementsPath).readAsStringSync();

    expect(
      entitlements,
      contains('com.apple.developer.associated-domains'),
    );
    expect(entitlements, contains('applinks:vitafolder.app'));
  });

  test('wires the entitlements file into the Runner target', () {
    final project = File(projectPath).readAsStringSync();

    expect(project, contains('Runner/Runner.entitlements'));
    expect(project, contains('CODE_SIGN_ENTITLEMENTS'));
  });
}
