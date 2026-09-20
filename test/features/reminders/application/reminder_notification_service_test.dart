import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/local_storage/local_storage_datasource.dart';
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_lead_time.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _MockStorage extends Mock implements LocalStorageDatasource {}

class _MockAndroidPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

void main() {
  late _MockPlugin plugin;
  late _MockStorage storage;
  late ReminderNotificationService service;

  setUpAll(() {
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(tz.TZDateTime.from(DateTime.utc(2030), tz.UTC));
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
      ),
    );
    registerFallbackValue(
      const AndroidNotificationChannel('id', 'name'),
    );
  });

  setUp(() {
    plugin = _MockPlugin();
    storage = _MockStorage();
    service = ReminderNotificationService(plugin: plugin, storage: storage);

    when(() => storage.getBool(any())).thenAnswer((_) async => false);
    when(() => storage.getString(any())).thenAnswer((_) async => null);
    when(
      () => storage.setBool(any(), value: any(named: 'value')),
    ).thenAnswer((_) async {});
    when(() => storage.setString(any(), any())).thenAnswer((_) async {});
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
      ),
    ).thenAnswer((_) async {});
  });

  group('pure helpers', () {
    test('notification id is stable, positive and unique per reminder', () {
      final first = ReminderNotificationService.notificationIdForReminder(
        'reminder-1',
      );
      final second = ReminderNotificationService.notificationIdForReminder(
        'reminder-1',
      );
      final other = ReminderNotificationService.notificationIdForReminder(
        'reminder-2',
      );

      expect(first, second);
      expect(first, greaterThanOrEqualTo(0));
      expect(first, lessThan(0x80000000));
      expect(other, isNot(first));
    });

    test('fire time subtracts the lead time', () {
      final due = DateTime(2026, 9, 1, 10, 30);
      expect(
        ReminderNotificationService.fireTimeFor(
          due,
          ReminderLeadTime.fifteenMinutes,
        ),
        DateTime(2026, 9, 1, 10, 15),
      );
      expect(
        ReminderNotificationService.fireTimeFor(due, ReminderLeadTime.atTime),
        due,
      );
      expect(
        ReminderNotificationService.fireTimeFor(due, ReminderLeadTime.oneDay),
        DateTime(2026, 8, 31, 10, 30),
      );
    });

    test('maps repeat rules to calendar components', () {
      expect(
        ReminderNotificationService.repeatComponentFor('daily'),
        DateTimeComponents.time,
      );
      expect(
        ReminderNotificationService.repeatComponentFor('weekly'),
        DateTimeComponents.dayOfWeekAndTime,
      );
      expect(ReminderNotificationService.repeatComponentFor('never'), isNull);
      expect(ReminderNotificationService.repeatComponentFor('monthly'), isNull);
    });

    test('skips one-shot notifications in the past', () {
      final now = DateTime(2026, 9, 1, 12);
      expect(
        ReminderNotificationService.shouldSchedule(
          fireTime: DateTime(2026, 9, 1, 13),
          repeatComponent: null,
          now: now,
        ),
        isTrue,
      );
      expect(
        ReminderNotificationService.shouldSchedule(
          fireTime: DateTime(2026, 9, 1, 11),
          repeatComponent: null,
          now: now,
        ),
        isFalse,
      );
      expect(
        ReminderNotificationService.shouldSchedule(
          fireTime: DateTime(2026, 9, 1, 11),
          repeatComponent: DateTimeComponents.time,
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('setReminderNotification', () {
    test('disabled choice cancels without scheduling', () async {
      await service.setReminderNotification(
        reminderId: 'r1',
        enabled: false,
        leadTime: ReminderLeadTime.fifteenMinutes,
        dueDate: DateTime(2030, 1, 1, 10),
        title: 'Title',
        body: 'Body',
        repeatRule: 'never',
      );

      verify(() => plugin.cancel(id: any(named: 'id'))).called(1);
      verifyNever(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
        ),
      );
      verify(
        () => storage.setBool('reminder_notify_enabled_r1', value: false),
      ).called(1);
    });

    test('schedules at due date minus lead time and persists choice', () async {
      final due = DateTime(2030, 5, 4, 9);

      await service.setReminderNotification(
        reminderId: 'r1',
        enabled: true,
        leadTime: ReminderLeadTime.fifteenMinutes,
        dueDate: due,
        title: 'Title',
        body: 'Body',
        repeatRule: 'never',
      );

      final captured = verify(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: captureAny(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          title: 'Title',
          body: 'Body',
        ),
      ).captured;
      final scheduled = captured.single as DateTime;
      expect(
        scheduled.millisecondsSinceEpoch,
        DateTime(2030, 5, 4, 8, 45).millisecondsSinceEpoch,
      );
      verify(
        () => storage.setBool('reminder_notify_enabled_r1', value: true),
      ).called(1);
      verify(
        () => storage.setString('reminder_notify_lead_minutes_r1', '15'),
      ).called(1);
    });

    test('skips one-shot schedule when fire time is in the past', () async {
      await service.setReminderNotification(
        reminderId: 'r1',
        enabled: true,
        leadTime: ReminderLeadTime.atTime,
        dueDate: DateTime(2020, 1, 1, 10),
        title: 'Title',
        body: 'Body',
        repeatRule: 'never',
      );

      verify(() => plugin.cancel(id: any(named: 'id'))).called(1);
      verifyNever(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
        ),
      );
      // Choice is still persisted for later edits.
      verify(
        () => storage.setBool('reminder_notify_enabled_r1', value: true),
      ).called(1);
    });

    test(
      'still schedules repeating notifications past their fire time',
      () async {
        await service.setReminderNotification(
          reminderId: 'r1',
          enabled: true,
          leadTime: ReminderLeadTime.atTime,
          dueDate: DateTime(2020, 1, 1, 10),
          title: 'Title',
          body: 'Body',
          repeatRule: 'daily',
        );

        // Repeating patterns always schedule: the plugin resolves the next
        // matching occurrence, so a past fire time must not skip scheduling.
        final captured = verify(
          () => plugin.zonedSchedule(
            id: any(named: 'id'),
            scheduledDate: any(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            title: 'Title',
            body: 'Body',
            matchDateTimeComponents: captureAny(
              named: 'matchDateTimeComponents',
            ),
          ),
        ).captured;
        expect(captured.single, DateTimeComponents.time);
      },
    );

    test('falls back to due date when the lead time elapsed', () async {
      final due = DateTime.now().add(const Duration(minutes: 5));

      await service.setReminderNotification(
        reminderId: 'r1',
        enabled: true,
        leadTime: ReminderLeadTime.fifteenMinutes,
        dueDate: due,
        title: 'Title',
        body: 'Body',
        repeatRule: 'never',
      );

      final captured = verify(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: captureAny(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          title: 'Title',
          body: 'Body',
        ),
      ).captured;
      final scheduled = captured.single as DateTime;
      expect(scheduled.millisecondsSinceEpoch, due.millisecondsSinceEpoch);
    });

    test('persists choice without scheduling when there is no date', () async {
      await service.setReminderNotification(
        reminderId: 'r1',
        enabled: true,
        leadTime: ReminderLeadTime.oneHour,
        dueDate: null,
        title: 'Title',
        body: 'Body',
        repeatRule: 'never',
      );

      verifyNever(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
        ),
      );
      verify(
        () => storage.setBool('reminder_notify_enabled_r1', value: true),
      ).called(1);
      verify(
        () => storage.setString('reminder_notify_lead_minutes_r1', '60'),
      ).called(1);
    });

    test(
      'edit reschedules: cancels previous then schedules new fire time',
      () async {
        const reminderId = 'r1';
        final expectedId =
            ReminderNotificationService.notificationIdForReminder(reminderId);
        final firstDue = DateTime(2030, 5, 4, 9);
        final secondDue = DateTime(2030, 5, 5, 10);

        await service.setReminderNotification(
          reminderId: reminderId,
          enabled: true,
          leadTime: ReminderLeadTime.fifteenMinutes,
          dueDate: firstDue,
          title: 'Title',
          body: 'Body',
          repeatRule: 'never',
        );
        await service.setReminderNotification(
          reminderId: reminderId,
          enabled: true,
          leadTime: ReminderLeadTime.fifteenMinutes,
          dueDate: secondDue,
          title: 'Title v2',
          body: 'Body v2',
          repeatRule: 'never',
        );

        // Old alert removed before the new one is scheduled, on the same id:
        // each set call cancels first (twice total) and schedules once.
        verify(() => plugin.cancel(id: expectedId)).called(2);

        final scheduledIds = verify(
          () => plugin.zonedSchedule(
            id: captureAny(named: 'id'),
            scheduledDate: captureAny(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            title: any(named: 'title'),
            body: any(named: 'body'),
          ),
        ).captured;
        // Captured [id, date, id, date] in call order.
        expect(scheduledIds, hasLength(4));
        expect(scheduledIds[0], expectedId);
        expect(scheduledIds[2], expectedId);
        final scheduled = [scheduledIds[1] as DateTime, scheduledIds[3]];
        expect(scheduled, hasLength(2));
        expect(
          (scheduled[1] as DateTime).millisecondsSinceEpoch,
          DateTime(2030, 5, 5, 9, 45).millisecondsSinceEpoch,
        );
      },
    );
    test('reports whether an alert was scheduled', () async {
      Future<bool> set({
        required bool enabled,
        required DateTime? dueDate,
      }) => service.setReminderNotification(
        reminderId: 'r1',
        enabled: enabled,
        leadTime: ReminderLeadTime.atTime,
        dueDate: dueDate,
        title: 'Title',
        body: 'Body',
        repeatRule: 'never',
      );

      // Scheduled in the future.
      expect(
        await set(enabled: true, dueDate: DateTime(2030, 1, 1, 10)),
        isTrue,
      );
      // Requested but the one-shot time already passed.
      expect(
        await set(enabled: true, dueDate: DateTime(2020, 1, 1, 10)),
        isFalse,
      );
      // Nothing requested: disabled or no date.
      expect(
        await set(enabled: false, dueDate: DateTime(2030, 1, 1, 10)),
        isTrue,
      );
      expect(await set(enabled: true, dueDate: null), isTrue);
    });
  });

  group('cancelReminderNotification', () {
    test('cancels the OS notification and clears the flag', () async {
      await service.cancelReminderNotification('r1');

      verify(() => plugin.cancel(id: any(named: 'id'))).called(1);
      verify(
        () => storage.setBool('reminder_notify_enabled_r1', value: false),
      ).called(1);
    });
  });

  group('system permission', () {
    test('returns false gracefully when the check cannot run', () async {
      // No platform channel in unit tests: permission_handler throws,
      // the service must degrade to false instead of crashing.
      expect(await service.hasSystemPermission(), isFalse);
      expect(await service.requestSystemPermission(), isFalse);
    });

    test('exact alarms report available off Android', () async {
      // Unit tests run on the host (not Android): must return true
      // without touching platform channels.
      expect(await service.canScheduleExactAlarms(), isTrue);
      await service.requestExactAlarmPermission();
    });
  });

  group('getReminderNotification', () {
    test('defaults to disabled with fifteen minutes lead', () async {
      final prefs = await service.getReminderNotification('r1');

      expect(prefs.enabled, isFalse);
      expect(prefs.leadTime, ReminderLeadTime.fifteenMinutes);
    });

    test('reads persisted choice', () async {
      when(
        () => storage.getBool('reminder_notify_enabled_r1'),
      ).thenAnswer((_) async => true);
      when(
        () => storage.getString('reminder_notify_lead_minutes_r1'),
      ).thenAnswer((_) async => '60');

      final prefs = await service.getReminderNotification('r1');

      expect(prefs.enabled, isTrue);
      expect(prefs.leadTime, ReminderLeadTime.oneHour);
    });
  });

  group('init', () {
    test('initializes plugin and creates channel', () async {
      final android = _MockAndroidPlugin();
      when(
        () => plugin.initialize(settings: any(named: 'settings')),
      ).thenAnswer((_) async => true);
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(
        () => android.createNotificationChannel(any()),
      ).thenAnswer((_) async {});

      await service.init();

      verify(
        () => plugin.initialize(settings: any(named: 'settings')),
      ).called(1);
      verify(() => android.createNotificationChannel(any())).called(1);
    });

    test('initializes with a drawable small icon', () async {
      final android = _MockAndroidPlugin();
      when(
        () => plugin.initialize(settings: any(named: 'settings')),
      ).thenAnswer((_) async => true);
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(
        () => android.createNotificationChannel(any()),
      ).thenAnswer((_) async {});

      await service.init();

      // The small icon must be a drawable silhouette: an adaptive-icon
      // mipmap is rejected by the OS and notifications never display.
      final captured = verify(
        () => plugin.initialize(settings: captureAny(named: 'settings')),
      ).captured;
      final settings = captured.single as InitializationSettings;
      expect(settings.android?.defaultIcon, '@drawable/ic_notification');
    });

    test('skips channel setup when platform lookup throws', () async {
      when(
        () => plugin.initialize(settings: any(named: 'settings')),
      ).thenAnswer((_) async => true);
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenThrow(Exception('no platform'));

      await service.init();

      verify(
        () => plugin.initialize(settings: any(named: 'settings')),
      ).called(1);
    });
  });

  group('android exact alarms', () {
    test('checks exact alarm capability on Android', () async {
      final androidService = ReminderNotificationService(
        plugin: plugin,
        storage: storage,
        isAndroidOverride: true,
      );
      final android = _MockAndroidPlugin();
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(
        android.canScheduleExactNotifications,
      ).thenAnswer((_) async => true);

      expect(await androidService.canScheduleExactAlarms(), isTrue);
    });

    test('returns false when Android check throws', () async {
      final androidService = ReminderNotificationService(
        plugin: plugin,
        storage: storage,
        isAndroidOverride: true,
      );
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenThrow(Exception('no platform'));

      expect(await androidService.canScheduleExactAlarms(), isFalse);
    });

    test('requests exact alarm permission on Android', () async {
      final androidService = ReminderNotificationService(
        plugin: plugin,
        storage: storage,
        isAndroidOverride: true,
      );

      // permission_handler has no platform channel in unit tests and
      // throws; the service must swallow it, covering the catch branch.
      await androidService.requestExactAlarmPermission();
    });

    test('uses exact schedule mode when allowed', () async {
      final androidService = ReminderNotificationService(
        plugin: plugin,
        storage: storage,
        isAndroidOverride: true,
      );
      final android = _MockAndroidPlugin();
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(
        android.canScheduleExactNotifications,
      ).thenAnswer((_) async => true);

      await androidService.setReminderNotification(
        reminderId: 'r1',
        enabled: true,
        leadTime: ReminderLeadTime.atTime,
        dueDate: DateTime(2030, 1, 1, 10),
        title: 'Title',
        body: 'Body',
        repeatRule: 'never',
      );

      final captured = verify(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: captureAny(named: 'androidScheduleMode'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
        ),
      ).captured;
      expect(
        captured.single,
        AndroidScheduleMode.exactAllowWhileIdle,
      );
    });

    test('falls back to inexact mode when exact check throws', () async {
      final androidService = ReminderNotificationService(
        plugin: plugin,
        storage: storage,
        isAndroidOverride: true,
      );
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenThrow(Exception('no platform'));

      await androidService.setReminderNotification(
        reminderId: 'r1',
        enabled: true,
        leadTime: ReminderLeadTime.atTime,
        dueDate: DateTime(2030, 1, 1, 10),
        title: 'Title',
        body: 'Body',
        repeatRule: 'never',
      );

      final captured = verify(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: captureAny(named: 'androidScheduleMode'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
        ),
      ).captured;
      expect(
        captured.single,
        AndroidScheduleMode.inexactAllowWhileIdle,
      );
    });
  });

  group('construction', () {
    test('defaults to a real plugin when none is given', () {
      expect(
        ReminderNotificationService(storage: storage),
        isA<ReminderNotificationService>(),
      );
    });
  });
}
