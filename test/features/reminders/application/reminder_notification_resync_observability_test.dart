import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/local_storage/local_storage_datasource.dart';
import 'package:house_mira/core/observability/app_logger.dart';
import 'package:house_mira/core/observability/crash_reporter.dart';
import 'package:house_mira/core/observability/performance_tracer.dart';
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';
import 'package:house_mira/features/reminders/application/time_zone_provider.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _MockStorage extends Mock implements LocalStorageDatasource {}

class _FakeTimeZoneProvider implements TimeZoneProvider {
  @override
  Future<void> configureLocal() async {}

  @override
  tz.TZDateTime fromLocal(DateTime dateTime) =>
      tz.TZDateTime.from(dateTime, tz.UTC);
}

class _RecordingCrashReporter implements CrashReporter {
  final logs = <String>[];
  final errors = <Object>[];

  @override
  Future<void> log(String message) async {
    logs.add(message);
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, Object?>? context,
    bool fatal = false,
  }) async {
    errors.add(error);
  }

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}
}

class _RecordingTraceHandle implements TraceHandle {
  final metrics = <String, int>{};
  var stops = 0;

  @override
  Future<void> putAttribute(String name, String value) async {}

  @override
  Future<void> putMetric(String name, int value) async {
    metrics[name] = value;
  }

  @override
  Future<void> stop() async {
    stops++;
  }
}

class _RecordingTracer implements PerformanceTracer {
  _RecordingTracer(this.handle);
  final _RecordingTraceHandle handle;
  final names = <String>[];

  @override
  Future<T> trace<T>(
    String name,
    Future<T> Function(TraceHandle trace) action, {
    Map<String, String>? attributes,
  }) async {
    names.add(name);
    try {
      return await action(handle);
    } finally {
      await handle.stop();
    }
  }

  @override
  Future<TraceHandle> startTrace(String name) async {
    names.add(name);
    return handle;
  }
}

void main() {
  late _MockPlugin plugin;
  late _MockStorage storage;
  late _RecordingCrashReporter crash;
  late _RecordingTraceHandle handle;
  late _RecordingTracer tracer;
  late List<String> lines;
  late ReminderNotificationService service;

  setUpAll(() {
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(tz.TZDateTime.from(DateTime.utc(2030), tz.UTC));
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
  });

  setUp(() {
    plugin = _MockPlugin();
    storage = _MockStorage();
    crash = _RecordingCrashReporter();
    handle = _RecordingTraceHandle();
    tracer = _RecordingTracer(handle);
    lines = <String>[];
    service = ReminderNotificationService(
      plugin: plugin,
      storage: storage,
      timeZoneProvider: _FakeTimeZoneProvider(),
      crashReporter: crash,
      logger: AppLogger(crashReporter: crash, sink: lines.add),
      tracer: tracer,
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

  void stubEnabled(String reminderId) {
    when(
      () => storage.getBool('reminder_notify_enabled_$reminderId'),
    ).thenAnswer((_) async => true);
    when(
      () => storage.getString('reminder_notify_lead_minutes_$reminderId'),
    ).thenAnswer((_) async => '15');
  }

  group('rescheduleAll observability', () {
    test('reports scheduled/skipped/failed counts on the trace', () async {
      stubEnabled('sched');
      stubEnabled('past');
      when(
        () => storage.getBool('reminder_notify_enabled_bad'),
      ).thenThrow(Exception('db'));

      await service.rescheduleAll([
        reminder('sched', '04/05/2030 09:00'),
        // One-shot in the past: requested but skipped, not failed.
        reminder('past', '01/01/2020 09:00'),
        // Disabled: skipped.
        reminder('off', '04/05/2030 09:00'),
        // Storage failure: failed, reported, rest continues.
        reminder('bad', '04/05/2030 09:00'),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(tracer.names, ['reminder-resync']);
      expect(handle.metrics['total'], 4);
      expect(handle.metrics['scheduled'], 1);
      expect(handle.metrics['skipped'], 2);
      expect(handle.metrics['failed'], 1);
      expect(handle.stops, 1);
      expect(
        lines.any((l) => l.contains('reminder resync completed')),
        isTrue,
      );
      // The bad entry is reported as a non-fatal with its reminder id.
      expect(crash.errors.single, isA<Exception>());
      expect(
        crash.logs.single,
        contains('[warning][reminder-resync] reminder resync skipped entry'),
      );
    });

    test('empty resync still traces and logs', () async {
      await service.rescheduleAll([]);
      await Future<void>.delayed(Duration.zero);

      expect(tracer.names, ['reminder-resync']);
      expect(handle.metrics['total'], 0);
      expect(handle.stops, 1);
      expect(
        lines.any((l) => l.contains('reminder resync completed')),
        isTrue,
      );
    });
  });
}
