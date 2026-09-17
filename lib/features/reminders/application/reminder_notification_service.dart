import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:house_mira/core/local_storage/local_storage_datasource.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_lead_time.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Per-reminder notification preference, persisted on-device.
///
/// Notifications are local-only: each device schedules its own alerts.
/// Nothing is sent to other family members.
class ReminderNotificationPrefs {
  final bool enabled;
  final ReminderLeadTime leadTime;

  const ReminderNotificationPrefs({
    required this.enabled,
    required this.leadTime,
  });

  static const disabled = ReminderNotificationPrefs(
    enabled: false,
    leadTime: ReminderLeadTime.defaultLeadTime,
  );
}

abstract interface class IReminderNotificationService {
  Future<void> init();

  /// Whether the OS allows this app to post notifications.
  /// Returns false (never throws) when the check cannot run.
  Future<bool> hasSystemPermission();

  /// Asks the OS for notification permission.
  /// Returns true when granted, false otherwise (never throws).
  Future<bool> requestSystemPermission();

  /// Whether exact alarms can be scheduled. Always true off Android;
  /// on Android 12+ it needs the "Alarms & reminders" system setting.
  /// Never throws.
  Future<bool> canScheduleExactAlarms();

  /// Opens the system screen where the user grants exact alarms (Android).
  /// No-op off Android. Never throws.
  Future<void> requestExactAlarmPermission();

  Future<ReminderNotificationPrefs> getReminderNotification(String reminderId);

  /// Persists the choice and (re)schedules or cancels the OS notification.
  ///
  /// When [enabled] is true but [dueDate] is null there is nothing to
  /// schedule yet; the choice is still persisted so a later edit that sets
  /// a date can schedule it.
  Future<void> setReminderNotification({
    required String reminderId,
    required bool enabled,
    required ReminderLeadTime leadTime,
    required DateTime? dueDate,
    required String title,
    required String body,
    required String repeatRule,
  });

  Future<void> cancelReminderNotification(String reminderId);
}

class ReminderNotificationService implements IReminderNotificationService {
  static const _channelId = 'reminders';
  static const _channelName = 'Reminders';
  static const _channelDescription = 'Reminder notifications';

  final FlutterLocalNotificationsPlugin _plugin;
  final LocalStorageDatasource _storage;
  final bool _isAndroid;
  static bool _timeZonesInitialized = false;

  ReminderNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    required LocalStorageDatasource storage,
    // Testing seam: Platform.isAndroid is always false on the CI host, so
    // the Android-only branches below would otherwise be uncoverable.
    @visibleForTesting bool? isAndroidOverride,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _storage = storage,
       _isAndroid = isAndroidOverride ?? Platform.isAndroid;

  static String _enabledKey(String reminderId) =>
      'reminder_notify_enabled_$reminderId';
  static String _leadKey(String reminderId) =>
      'reminder_notify_lead_minutes_$reminderId';

  /// Deterministic, content-based id (String.hashCode is not guaranteed
  /// stable across runs, so it cannot be used for ids that must survive
  /// process restarts and still be cancellable).
  @visibleForTesting
  static int notificationIdForReminder(String reminderId) {
    var hash = 0;
    for (final code in reminderId.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash;
  }

  @visibleForTesting
  static DateTime fireTimeFor(DateTime dueDate, ReminderLeadTime leadTime) {
    return dueDate.subtract(Duration(minutes: leadTime.minutes));
  }

  /// Maps repeat rules to calendar components. Monthly has no matching
  /// component (dateAndTime repeats yearly), so it fires once and the next
  /// occurrence is scheduled on the following edit/save.
  @visibleForTesting
  static DateTimeComponents? repeatComponentFor(String repeatRule) {
    switch (repeatRule) {
      case 'daily':
        return DateTimeComponents.time;
      case 'weekly':
        return DateTimeComponents.dayOfWeekAndTime;
      default:
        return null;
    }
  }

  /// One-shot notifications in the past can never fire, so they are skipped.
  /// Repeating patterns always schedule: the plugin resolves the next
  /// matching occurrence from now.
  @visibleForTesting
  static bool shouldSchedule({
    required DateTime fireTime,
    required DateTimeComponents? repeatComponent,
    required DateTime now,
  }) {
    if (repeatComponent != null) return true;
    return fireTime.isAfter(now);
  }

  @override
  Future<void> init() async {
    _ensureTimeZones();
    try {
      final timeZoneName =
          (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName)); // coverage:ignore-line
    } catch (_) {
      debugPrint('ReminderNotificationService: using default time zone.');
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      // System permission is already requested at startup by
      // NotificationPermissionService; do not prompt again here.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);

    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
        ),
      );
    } catch (_) {
      debugPrint('ReminderNotificationService: channel setup skipped.');
    }
  }

  @override
  Future<bool> hasSystemPermission() async {
    try {
      return await Permission.notification.isGranted;
    } catch (_) {
      debugPrint('ReminderNotificationService: permission check failed.');
      return false;
    }
  }

  @override
  Future<bool> requestSystemPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted; // coverage:ignore-line
    } catch (_) {
      debugPrint('ReminderNotificationService: permission request failed.');
      return false;
    }
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    if (!_isAndroid) return true;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.canScheduleExactNotifications() ?? false;
    } catch (_) {
      debugPrint('ReminderNotifications: exact alarm check failed.');
      return false;
    }
  }

  @override
  Future<void> requestExactAlarmPermission() async {
    if (!_isAndroid) return;
    try {
      await Permission.scheduleExactAlarm.request();
    } catch (_) {
      debugPrint('ReminderNotifications: exact alarm request failed.');
    }
  }

  @override
  Future<ReminderNotificationPrefs> getReminderNotification(
    String reminderId,
  ) async {
    final enabled = await _storage.getBool(_enabledKey(reminderId));
    final leadTime =
        ReminderLeadTime.fromMinutes(
          int.tryParse(await _storage.getString(_leadKey(reminderId)) ?? ''),
        ) ??
        ReminderLeadTime.defaultLeadTime;
    return ReminderNotificationPrefs(enabled: enabled, leadTime: leadTime);
  }

  @override
  Future<void> setReminderNotification({
    required String reminderId,
    required bool enabled,
    required ReminderLeadTime leadTime,
    required DateTime? dueDate,
    required String title,
    required String body,
    required String repeatRule,
  }) async {
    _ensureTimeZones();
    await _plugin.cancel(id: notificationIdForReminder(reminderId));
    await _storage.setBool(_enabledKey(reminderId), enabled);
    await _storage.setString(_leadKey(reminderId), '${leadTime.minutes}');

    if (!enabled || dueDate == null) {
      debugPrint(
        'ReminderNotifications: skipping $reminderId '
        '(enabled=$enabled, dueDate=$dueDate).',
      );
      return;
    }

    var fireTime = fireTimeFor(dueDate, leadTime);
    final repeatComponent = repeatComponentFor(repeatRule);
    final now = DateTime.now();
    if (!shouldSchedule(
      fireTime: fireTime,
      repeatComponent: repeatComponent,
      now: now,
    )) {
      if (repeatComponent == null && dueDate.isAfter(now)) {
        // The lead time already elapsed (e.g. editing a reminder due in
        // 10 min with a 15 min lead): fall back to alerting at due time
        // instead of staying silent.
        debugPrint(
          'ReminderNotifications: fire time $fireTime elapsed, '
          'falling back to due date $dueDate for $reminderId.',
        );
        fireTime = dueDate;
      } else {
        debugPrint(
          'ReminderNotifications: skipping $reminderId '
          '(due date $dueDate already passed).',
        );
        return;
      }
    }

    await _plugin.zonedSchedule(
      id: notificationIdForReminder(reminderId),
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(fireTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: await _scheduleMode(),
      matchDateTimeComponents: repeatComponent,
    );
    debugPrint(
      'ReminderNotifications: scheduled $reminderId '
      '(notification #${notificationIdForReminder(reminderId)}) '
      'at $fireTime (lead ${leadTime.minutes}m, repeat $repeatRule).',
    );
  }

  @override
  Future<void> cancelReminderNotification(String reminderId) async {
    await _plugin.cancel(id: notificationIdForReminder(reminderId));
    await _storage.setBool(_enabledKey(reminderId), false);
  }

  static void _ensureTimeZones() {
    if (_timeZonesInitialized) return;
    tz.initializeTimeZones();
    _timeZonesInitialized = true;
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final canScheduleExact =
          await android?.canScheduleExactNotifications() ?? false;
      if (canScheduleExact) return AndroidScheduleMode.exactAllowWhileIdle;
    } catch (_) {
      debugPrint('ReminderNotificationService: exact alarm check skipped.');
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }
}
