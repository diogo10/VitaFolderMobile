import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the manifest entries `flutter_local_notifications` needs at
/// runtime. The plugin declares the receiver classes but not the manifest
/// entries: without `ScheduledNotificationReceiver`, the OS accepts alarms
/// yet drops them at fire time — schedules succeed, `show()` works, and no
/// scheduled notification is ever displayed (with nothing in the logs).
void main() {
  const manifestPath = 'android/app/src/main/AndroidManifest.xml';
  const fireReceiver =
      'android:name="com.dexterous.flutterlocalnotifications.'
      'ScheduledNotificationReceiver"';
  const bootReceiver =
      'android:name="com.dexterous.flutterlocalnotifications.'
      'ScheduledNotificationBootReceiver"';

  test('declares the scheduled-notification fire receiver', () {
    final manifest = File(manifestPath).readAsStringSync();

    expect(manifest, contains(fireReceiver));
  });

  test('declares the boot receiver with its permissions', () {
    final manifest = File(manifestPath).readAsStringSync();

    expect(manifest, contains(bootReceiver));
    expect(
      manifest,
      contains('android.permission.RECEIVE_BOOT_COMPLETED'),
    );
  });

  test('declares notification and exact-alarm permissions', () {
    final manifest = File(manifestPath).readAsStringSync();

    expect(
      manifest,
      contains('android.permission.POST_NOTIFICATIONS'),
    );
    expect(
      manifest,
      contains('android.permission.SCHEDULE_EXACT_ALARM'),
    );
  });

  test('declares the family-invite App Link', () {
    final manifest = File(manifestPath).readAsStringSync();

    expect(manifest, contains('android.intent.action.VIEW'));
    expect(manifest, contains('android.intent.category.BROWSABLE'));
    expect(manifest, contains('android:host="housemira.com"'));
    expect(manifest, contains('android:pathPrefix="/invite"'));
  });

  group('notification small icon', () {
    const servicePath =
        'packages/house_mira_reminders/lib/application/'
        'reminder_notification_service.dart';
    const drawableDir = 'android/app/src/main/res/drawable';

    /// The bare drawable name the plugin resolves with
    /// `Resources.getIdentifier(name, "drawable", packageName)`. A qualified
    /// name such as `@drawable/ic_notification` resolves to 0 and makes
    /// `initialize()` fail with `invalid_icon`, which leaves the default
    /// small icon unresolved and drops every reminder notification.
    final iconName = RegExp(
      r"AndroidInitializationSettings\('([^']+)'\)",
    ).firstMatch(File(servicePath).readAsStringSync())?.group(1);

    test('the service passes a bare drawable resource name', () {
      expect(iconName, isNotNull);
      expect(iconName, isNot(contains('@')));
      expect(iconName, isNot(contains('/')));
    });

    test('the referenced drawable exists in the Android resources', () {
      expect(iconName, isNotNull);

      final drawable = File('$drawableDir/$iconName.xml');

      expect(
        drawable.existsSync(),
        isTrue,
        reason:
            'missing ${drawable.path}; the notification small icon must be a '
            'white-on-transparent silhouette, not an adaptive-icon mipmap',
      );
    });

    test('release resource shrinking keeps the small icon', () {
      expect(iconName, isNotNull);

      // Flutter's Gradle plugin enables `isShrinkResources` for release app
      // builds, so a drawable referenced only by name from Dart is stripped
      // from the APK/AAB: `getIdentifier(...)` then returns 0 at runtime and
      // the plugin throws `invalid_icon` (Crashlytics `434603cf`). The
      // `tools:keep` entry in res/raw/keep.xml is what stops that.
      final keep = File('android/app/src/main/res/raw/keep.xml');

      expect(
        keep.existsSync(),
        isTrue,
        reason:
            'missing ${keep.path}; the shrinker strips drawables that are '
            'only referenced by name at runtime',
      );
      expect(
        keep.readAsStringSync(),
        contains('tools:keep="@drawable/$iconName"'),
      );
    });
  });
}
