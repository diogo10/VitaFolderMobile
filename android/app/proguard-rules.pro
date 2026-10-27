# App-level R8 keep rules for the `release` build (AGP 9 / R8 full mode).
#
# Everything the build already needs is added by the toolchain, so this file
# intentionally ships no rules today:
#   * Flutter engine + Gradle plugin rules:
#     flutter_tools/gradle/flutter_proguard_rules.pro
#   * `proguard-android-optimize.txt`, added by the Flutter Gradle plugin.
#   * Library/plugin consumer rules (Firebase, RevenueCat, permission_handler,
#     flutter_local_notifications, ...) bundled in each AAR.
#
# Only add a rule here when a release build demonstrably strips something that
# is reached reflectively, and keep it as narrow as possible (prefer
# `-keepclassmembers` / `-if ... -keep <1>` over `-keep class pkg.**`) so R8 can
# stay aggressive. Verify with:
#   fvm flutter build appbundle --release --dart-define-from-file=env/dev.json
#   unzip -p build/app/outputs/bundle/release/app-release.aab \
#     BUNDLE-METADATA/com.android.tools/r8.json
