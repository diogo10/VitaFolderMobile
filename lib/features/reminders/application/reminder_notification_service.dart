import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:house_mira/core/local_storage/local_storage_datasource.dart';
import 'package:house_mira/core/observability/app_logger.dart';
import 'package:house_mira/core/observability/crash_reporter.dart';
import 'package:house_mira/core/observability/performance_tracer.dart';
import 'package:house_mira/features/reminders/application/time_zone_provider.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_lead_time.dart';
import 'package:house_mira/features/reminders/domain/utils/reminder_date_utils.dart';
import 'package:permission_handler/permission_handler.dart';

/// Per-reminder notification preference, persisted on-device.
///
/// Notifications are local-only: each device schedules its own alerts.
/// Nothing is sent to other family members.
class ReminderNotificationPrefs {
  const ReminderNotificationPrefs({
    required this.enabled,
    required this.leadTime,
  });
  final bool enabled;
  final ReminderLeadTime leadTime;

  static const disabled = ReminderNotificationPrefs(
    enabled: false,
    leadTime: ReminderLeadTime.defaultLeadTime,
  );
}

abstract interface class IReminderNotificationService {
  Future<void> init();

  /// Payloads (`reminderId`s) of tapped notifications.
  Stream<String?> get onNotificationTap;

  /// Payload that cold-started the app via a notification, if any.
  /// Returns null (never throws) when there is none or the check fails.
  Future<String?> getLaunchPayload();

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
  ///
  /// Returns true when an alert was scheduled or nothing was requested
  /// (disabled / no date). Returns false when an alert was requested but
  /// skipped because the (one-shot) time already passed.
  Future<bool> setReminderNotification({
    required String reminderId,
    required bool enabled,
    required ReminderLeadTime leadTime,
    required DateTime? dueDate,
    required String title,
    required String body,
    required String repeatRule,
  });

  Future<void> cancelReminderNotification(String reminderId);

  /// Shows an immediate test notification via `show()`, bypassing
  /// AlarmManager scheduling. Isolates channel/icon delivery problems
  /// from scheduling problems. Returns true when posted, false otherwise
  /// (never throws).
  Future<bool> showTestNotification({
    required String title,
    required String body,
  });

  /// Re-schedules every enabled reminder after reboot, reinstall, or a
  /// cold start that cleared OS alarms. Best-effort per item: one bad
  /// entry never aborts the rest. Never throws.
  Future<void> rescheduleAll(List<ReminderEntity> reminders);
}

class ReminderNotificationService implements IReminderNotificationService {
  ReminderNotificationService({
    required LocalStorageDatasource storage,
    FlutterLocalNotificationsPlugin? plugin,
    TimeZoneProvider? timeZoneProvider,
    CrashReporter? crashReporter,
    AppLogger? logger,
    PerformanceTracer? tracer,
    // Testing seam: Platform.isAndroid is always false on the CI host, so
    // the Android-only branches below would otherwise be uncoverable.
    @visibleForTesting bool? isAndroidOverride,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _storage = storage,
       _timeZoneProvider = timeZoneProvider ?? DeviceTimeZoneProvider(),
       _logger = logger ?? AppLogger(crashReporter: crashReporter),
       _tracer = tracer ?? NoOpPerformanceTracer(),
       _isAndroid = isAndroidOverride ?? Platform.isAndroid;
  static const _channelId = 'reminders';
  static const _channelName = 'Reminders';
  static const _channelDescription = 'Reminder notifications';

  /// Fixed id for the diagnostic test notification. Below 2^31 so it fits
  /// Android's int32 notification ids, and far from content-hashed ids.
  static const _testNotificationId = 2147483000;

  static const _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  final FlutterLocalNotificationsPlugin _plugin;
  final LocalStorageDatasource _storage;
  final TimeZoneProvider _timeZoneProvider;
  final AppLogger _logger;
  final PerformanceTracer _tracer;
  final bool _isAndroid;
  final StreamController<String?> _taps = StreamController<String?>.broadcast();

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
  Stream<String?> get onNotificationTap => _taps.stream;

  /// Closes the tap stream. Call once when the service is discarded
  /// (tests, hot-restart of DI).
  void dispose() => unawaited(_taps.close());

  @override
  Future<String?> getLaunchPayload() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      return details?.notificationResponse?.payload;
    } on Object catch (_) {
      debugPrint('ReminderNotificationService: launch payload check failed.');
      return null;
    }
  }

  @override
  Future<void> init() async {
    await _ensureLocalTimeZone();

    const settings = InitializationSettings(
      // Must be a white-on-transparent drawable: an adaptive-icon mipmap
      // is not a valid small icon and notifications using one are dropped
      // by the OS at fire time.
      android: AndroidInitializationSettings('@drawable/ic_notification'),
      // System permission is already requested at startup by
      // NotificationPermissionService; do not prompt again here.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        _taps.add(response.payload);
      },
    );

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
    } on Object catch (_) {
      debugPrint('ReminderNotificationService: channel setup skipped.');
    }
  }

  @override
  Future<bool> hasSystemPermission() async {
    try {
      return await Permission.notification.isGranted;
    } on Object catch (_) {
      debugPrint('ReminderNotificationService: permission check failed.');
      return false;
    }
  }

  @override
  Future<bool> requestSystemPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted; // coverage:ignore-line
    } on Object catch (_) {
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
    } on Object catch (_) {
      debugPrint('ReminderNotifications: exact alarm check failed.');
      return false;
    }
  }

  @override
  Future<void> requestExactAlarmPermission() async {
    if (!_isAndroid) return;
    try {
      await Permission.scheduleExactAlarm.request();
    } on Object catch (_) {
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
  Future<bool> setReminderNotification({
    required String reminderId,
    required bool enabled,
    required ReminderLeadTime leadTime,
    required DateTime? dueDate,
    required String title,
    required String body,
    required String repeatRule,
  }) async {
    await _ensureLocalTimeZone();
    await _plugin.cancel(id: notificationIdForReminder(reminderId));
    await _storage.setBool(_enabledKey(reminderId), value: enabled);
    await _storage.setString(_leadKey(reminderId), '${leadTime.minutes}');

    if (!enabled || dueDate == null) {
      debugPrint(
        'ReminderNotifications: skipping $reminderId '
        '(enabled=$enabled, dueDate=$dueDate).',
      );
      return true;
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
        return false;
      }
    }

    final scheduleMode = await _scheduleMode();
    final scheduledDate = _timeZoneProvider.fromLocal(fireTime);
    await _plugin.zonedSchedule(
      id: notificationIdForReminder(reminderId),
      title: title,
      body: body,
      payload: reminderId,
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails,
      androidScheduleMode: scheduleMode,
      matchDateTimeComponents: repeatComponent,
    );
    // Best-effort diagnostics only: zonedSchedule succeeding does NOT mean
    // the OS will deliver (permission denied / inexact delay / force-stop
    // all drop silently), so log everything needed to tell those apart.
    var systemPermission = false;
    var exactAlarms = false;
    try {
      systemPermission = await hasSystemPermission();
    } on Object catch (_) {
      // Logged below as false.
    }
    try {
      exactAlarms = await canScheduleExactAlarms();
    } on Object catch (_) {
      // Logged below as false.
    }
    var pendingCount = -1;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      pendingCount = pending.length;
    } on Object catch (_) {
      // Plugin may be uninitialized in tests; leave as -1 (unknown).
    }
    debugPrint(
      'ReminderNotifications: scheduled $reminderId '
      '(notification #${notificationIdForReminder(reminderId)}) '
      'at $fireTime (utc=${fireTime.toUtc()}, now=$now, '
      'scheduled=$scheduledDate, '
      'lead ${leadTime.minutes}m, repeat $repeatRule, mode=$scheduleMode, '
      'systemPermission=$systemPermission, exactAlarms=$exactAlarms, '
      'pending=$pendingCount).',
    );
    return true;
  }

  @override
  Future<bool> showTestNotification({
    required String title,
    required String body,
  }) async {
    try {
      await _plugin.show(
        id: _testNotificationId,
        title: title,
        body: body,
        notificationDetails: _notificationDetails,
        payload: 'test',
      );
      debugPrint('ReminderNotifications: test notification posted.');
      return true;
    } on Object catch (_) {
      debugPrint('ReminderNotifications: test notification failed.');
      return false;
    }
  }

  @override
  Future<void> cancelReminderNotification(String reminderId) async {
    await _plugin.cancel(id: notificationIdForReminder(reminderId));
    await _storage.setBool(_enabledKey(reminderId), value: false);
  }

  @override
  Future<void> rescheduleAll(List<ReminderEntity> reminders) async {
    await _tracer.trace(
      'reminder-resync',
      (trace) async {
        var scheduled = 0;
        var skipped = 0;
        var failed = 0;
        for (final reminder in reminders) {
          try {
            final prefs = await getReminderNotification(reminder.id);
            if (!prefs.enabled) {
              skipped++;
              continue;
            }
            final dueDate = ReminderDateUtils.parseDueDate(reminder.dueDate);
            if (dueDate == null) {
              skipped++;
              continue;
            }
            final ok = await setReminderNotification(
              reminderId: reminder.id,
              enabled: true,
              leadTime: prefs.leadTime,
              dueDate: dueDate,
              title: reminder.title,
              body: reminder.body,
              repeatRule: reminder.repeatRule,
            );
            if (ok) {
              scheduled++;
            } else {
              skipped++;
            }
          } on Object catch (error, stackTrace) {
            failed++;
            _logger.warning(
              'reminder resync skipped entry',
              tag: 'reminder-resync',
              context: {'reminder_id': reminder.id},
              error: error,
              stackTrace: stackTrace,
            );
          }
        }
        await trace.putMetric('total', reminders.length);
        await trace.putMetric('scheduled', scheduled);
        await trace.putMetric('skipped', skipped);
        await trace.putMetric('failed', failed);
        _logger.info(
          'reminder resync completed',
          tag: 'reminder-resync',
          context: {
            'total': reminders.length,
            'scheduled': scheduled,
            'skipped': skipped,
            'failed': failed,
          },
        );
      },
    );
  }

  Future<void> _ensureLocalTimeZone() async {
    try {
      await _timeZoneProvider.configureLocal();
    } on Object catch (_) {
      debugPrint('ReminderNotificationService: using default time zone.');
    }
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
    } on Object catch (_) {
      debugPrint('ReminderNotificationService: exact alarm check skipped.');
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }
}
