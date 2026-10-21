import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the iOS Universal Link wiring for family invites
/// (`https://housemira.com/invite/<code>`, handled in-app by the
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
    expect(entitlements, contains('applinks:housemira.com'));
  });

  test('wires the entitlements file into the Runner target', () {
    final project = File(projectPath).readAsStringSync();

    expect(project, contains('Runner/Runner.entitlements'));
    expect(project, contains('CODE_SIGN_ENTITLEMENTS'));
  });

  test('declares the Sign in with Apple capability', () {
    final entitlements = File(entitlementsPath).readAsStringSync();
    final project = File(projectPath).readAsStringSync();

    // The entitlement is what lets the app show the native Apple ID
    // sheet: without it the sign-in fails without any visible error.
    expect(entitlements, contains('com.apple.developer.applesignin'));
    expect(entitlements, contains('Default'));
    expect(project, contains('com.apple.SignInWithApple'));
  });
}
