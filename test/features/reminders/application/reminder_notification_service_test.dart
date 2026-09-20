import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/local_storage/local_storage_datasource.dart';
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';
import 'package:house_mira/features/reminders/application/time_zone_provider.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_lead_time.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _MockStorage extends Mock implements LocalStorageDatasource {}

class _MockAndroidPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class _FakeTimeZoneProvider implements TimeZoneProvider {
  int configureCalls = 0;
  bool shouldThrow = false;

  @override
  Future<void> configureLocal() async {
    configureCalls++;
    if (shouldThrow) throw Exception('tz fail');
  }

  @override
  tz.TZDateTime fromLocal(DateTime dateTime) =>
      tz.TZDateTime.from(dateTime, tz.UTC);
}

void main() {
  late _MockPlugin plugin;
  late _MockStorage storage;
  late _FakeTimeZoneProvider timeZoneProvider;
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
    registerFallbackValue((NotificationResponse _) {});
  });

  setUp(() {
    plugin = _MockPlugin();
    storage = _MockStorage();
    timeZoneProvider = _FakeTimeZoneProvider();
    service = ReminderNotificationService(
      plugin: plugin,
      storage: storage,
      timeZoneProvider: timeZoneProvider,
    );

    when(() => storage.getBool(any())).thenAnswer((_) async => false);
    when(() => storage.getString(any())).thenAnswer((_) async => null);
    when(
      () => storage.setBool(any(), value: any(named: 'value')),
    ).thenAnswer((_) async {});
    when(() => storage.setString(any(), any())).thenAnswer((_) async {});
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});
    when(
      () => plugin.pendingNotificationRequests(),
    ).thenAnswer((_) async => []);
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
        matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() {
    service.dispose();
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
          payload: any(named: 'payload'),
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
          payload: 'r1',
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
      // The device time zone is resolved on every schedule, not just init.
      expect(timeZoneProvider.configureCalls, 1);
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
          payload: any(named: 'payload'),
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
            payload: 'r1',
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
          payload: 'r1',
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
          payload: any(named: 'payload'),
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
            payload: any(named: 'payload'),
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

    test('still schedules when time-zone resolution fails', () async {
      timeZoneProvider.shouldThrow = true;

      final scheduled = await service.setReminderNotification(
        reminderId: 'r1',
        enabled: true,
        leadTime: ReminderLeadTime.atTime,
        dueDate: DateTime(2030, 1, 1, 10),
        title: 'Title',
        body: 'Body',
        repeatRule: 'never',
      );

      expect(scheduled, isTrue);
      verify(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          title: 'Title',
          body: 'Body',
          payload: 'r1',
        ),
      ).called(1);
    });
  });

  group('showTestNotification', () {
    test('posts immediately without scheduling', () async {
      when(
        () => plugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      expect(
        await service.showTestNotification(title: 'T', body: 'B'),
        isTrue,
      );

      final postedIds = verify(
        () => plugin.show(
          id: captureAny(named: 'id'),
          title: 'T',
          body: 'B',
          notificationDetails: any(named: 'notificationDetails'),
          payload: 'test',
        ),
      ).captured;
      // Fits Android's int32 notification ids.
      expect(postedIds.single as int, lessThan(0x80000000));
      // Bypasses the scheduler entirely: no alarm is armed.
      verifyNever(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('returns false when posting throws', () async {
      when(
        () => plugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).thenThrow(Exception('os'));

      expect(
        await service.showTestNotification(title: 'T', body: 'B'),
        isFalse,
      );
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

  group('notification taps', () {
    test('emits the payload of tapped notifications', () async {
      final android = _MockAndroidPlugin();
      when(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
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

      final captured = verify(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: captureAny(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).captured;
      final callback = captured.single as void Function(NotificationResponse);

      final expectation = expectLater(service.onNotificationTap, emits('r1'));
      callback(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'r1',
        ),
      );
      await expectation;
    });

    test('returns the cold-start payload when launched from a tap', () async {
      when(
        () => plugin.getNotificationAppLaunchDetails(),
      ).thenAnswer(
        (_) async => const NotificationAppLaunchDetails(
          true,
          notificationResponse: NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: 'r1',
          ),
        ),
      );

      expect(await service.getLaunchPayload(), 'r1');
    });

    test('returns null when no launch notification exists', () async {
      when(
        () => plugin.getNotificationAppLaunchDetails(),
      ).thenAnswer((_) async => null);

      expect(await service.getLaunchPayload(), isNull);
    });

    test('returns null when the launch check throws', () async {
      when(
        () => plugin.getNotificationAppLaunchDetails(),
      ).thenThrow(Exception('no platform'));

      expect(await service.getLaunchPayload(), isNull);
    });
  });

  group('rescheduleAll', () {
    ReminderEntity reminder(String id, String dueDate) => ReminderEntity(
      title: 'T $id',
      body: 'B $id',
      id: id,
      type: ReminderType.custom,
      dueDate: dueDate,
      repeatRule: 'never',
      status: 'pending',
      createdBy: 'Mom',
      createdAt: '',
    );

    void stubEnabled(String reminderId, {String leadMinutes = '15'}) {
      when(
        () => storage.getBool('reminder_notify_enabled_$reminderId'),
      ).thenAnswer((_) async => true);
      when(
        () => storage.getString('reminder_notify_lead_minutes_$reminderId'),
      ).thenAnswer((_) async => leadMinutes);
    }

    test('schedules every enabled reminder with a date', () async {
      stubEnabled('r1');

      await service.rescheduleAll([reminder('r1', '04/05/2030 09:00')]);

      verify(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          title: 'T r1',
          body: 'B r1',
          payload: 'r1',
        ),
      ).called(1);
    });

    test('skips disabled reminders', () async {
      await service.rescheduleAll([reminder('r1', '04/05/2030 09:00')]);

      verifyNever(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('skips enabled reminders without a date', () async {
      stubEnabled('r1');

      await service.rescheduleAll([reminder('r1', '')]);

      verifyNever(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('one bad entry never aborts the rest', () async {
      when(
        () => storage.getBool('reminder_notify_enabled_bad'),
      ).thenThrow(Exception('db'));
      stubEnabled('good');

      await service.rescheduleAll([
        reminder('bad', '04/05/2030 09:00'),
        reminder('good', '04/05/2030 09:00'),
      ]);

      verify(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          title: 'T good',
          body: 'B good',
          payload: 'good',
        ),
      ).called(1);
    });

    test('a failing schedule never throws', () async {
      stubEnabled('r1');
      when(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
        ),
      ).thenThrow(Exception('os'));

      await service.rescheduleAll([reminder('r1', '04/05/2030 09:00')]);
    });
  });

  group('init', () {
    test('initializes plugin and creates channel', () async {
      final android = _MockAndroidPlugin();
      when(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
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
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).called(1);
      verify(() => android.createNotificationChannel(any())).called(1);
      expect(timeZoneProvider.configureCalls, 1);
    });

    test('initializes with a drawable small icon', () async {
      final android = _MockAndroidPlugin();
      when(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
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
        () => plugin.initialize(
          settings: captureAny(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).captured;
      final settings = captured.single as InitializationSettings;
      expect(settings.android?.defaultIcon, '@drawable/ic_notification');
    });

    test('skips channel setup when platform lookup throws', () async {
      when(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenThrow(Exception('no platform'));

      await service.init();

      verify(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).called(1);
    });

    test('still initializes when time-zone resolution fails', () async {
      timeZoneProvider.shouldThrow = true;
      when(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(null);

      await service.init();

      verify(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).called(1);
    });
  });

  group('android exact alarms', () {
    test('checks exact alarm capability on Android', () async {
      final androidService = ReminderNotificationService(
        plugin: plugin,
        storage: storage,
        timeZoneProvider: timeZoneProvider,
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
        timeZoneProvider: timeZoneProvider,
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
        timeZoneProvider: timeZoneProvider,
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
        timeZoneProvider: timeZoneProvider,
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
        timeZoneProvider: timeZoneProvider,
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

    test('dispose closes the tap stream', () async {
      final android = _MockAndroidPlugin();
      when(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
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

      service.dispose();

      await expectLater(service.onNotificationTap, emitsDone);
    });
  });
}
