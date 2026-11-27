import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the Android packaging setting that keeps Flutter's engine loadable.
///
/// Flutter loads `libflutter.so` through ReLinker. When `System.loadLibrary`
/// fails, ReLinker's `ApkLibraryInstaller` scans the *base* APK for `lib/`.
/// A Play-distributed AAB keeps the native libraries in per-ABI config
/// splits, so with the AGP default of uncompressed libraries the base APK
/// has no `lib/` and the installer throws `MissingLibraryException` before
/// Dart starts (Crashlytics `ApkLibraryInstaller.installLibrary`).
///
/// `useLegacyPackaging = true` makes the package manager extract the
/// libraries at install time, so `System.loadLibrary` succeeds and ReLinker
/// never reaches its base-APK scanner.
void main() {
  const gradlePath = 'android/app/build.gradle.kts';
  const manifestPath = 'android/app/src/main/AndroidManifest.xml';

  /// Drops `//` comments so a commented-out setting cannot satisfy the guard.
  String withoutLineComments(String source) => source
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  test('enables legacy native-library packaging', () {
    final gradle = withoutLineComments(File(gradlePath).readAsStringSync());

    expect(gradle, contains('packaging {'));
    expect(gradle, contains('jniLibs {'));
    expect(gradle, contains('useLegacyPackaging = true'));
  });

  test('does not force uncompressed native libraries in the manifest', () {
    final manifest = File(manifestPath).readAsStringSync();

    expect(manifest, isNot(contains('android:extractNativeLibs="false"')));
  });
}
