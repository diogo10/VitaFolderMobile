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
}
