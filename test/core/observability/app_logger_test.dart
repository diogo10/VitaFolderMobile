import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/observability/app_logger.dart';
import 'package:house_mira/core/observability/crash_reporter.dart';

class _FakeCrashReporter implements CrashReporter {
  final logs = <String>[];
  final errors = <Object>[];
  final reasons = <String?>[];
  final userIds = <String?>[];
  final keys = <String, Object>{};

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
    reasons.add(reason);
  }

  @override
  Future<void> setUserId(String? userId) async {
    userIds.add(userId);
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    keys[key] = value;
  }
}

void main() {
  group('AppLogger', () {
    test(
      'debug/info emit structured lines without touching Crashlytics',
      () async {
        final lines = <String>[];
        final crash = _FakeCrashReporter();
        final logger = AppLogger(crashReporter: crash, sink: lines.add);

        logger.debug('hello', tag: 't', context: {'a': 1});
        logger.info('world');

        expect(lines, hasLength(2));
        expect(lines[0], '[debug][t] hello {a: 1}');
        expect(lines[1], '[info][app] world');
        expect(crash.logs, isEmpty);
        expect(crash.errors, isEmpty);
        await Future<void>.delayed(Duration.zero);
        expect(crash.logs, isEmpty);
      },
    );

    test(
      'warning forwards a breadcrumb and reports when given an error',
      () async {
        final lines = <String>[];
        final crash = _FakeCrashReporter();
        final logger = AppLogger(crashReporter: crash, sink: lines.add);

        logger.warning('slow', tag: 'auth', context: {'ms': 1});
        logger.warning(
          'boom',
          tag: 'edge',
          error: StateError('x'),
          stackTrace: StackTrace.empty,
        );
        await Future<void>.delayed(Duration.zero);

        // Breadcrumb for both, non-fatal report only for the error one.
        expect(crash.logs, hasLength(2));
        expect(crash.errors, hasLength(1));
        expect(lines[0], contains('[warning][auth] slow'));
      },
    );

    test('error always records a non-fatal report', () async {
      final crash = _FakeCrashReporter();
      final logger = AppLogger(crashReporter: crash, sink: (_) {});
      final stack = StackTrace.empty;

      logger.error(
        'failed',
        tag: 'startup',
        context: {'flavor': 'dev'},
        error: StateError('nope'),
        stackTrace: stack,
      );
      await Future<void>.delayed(Duration.zero);

      expect(crash.logs.single, contains('[error][startup] failed'));
      expect(crash.errors.single, isA<StateError>());
      expect(crash.reasons.single, '[error][startup] failed');
    });

    test('error without an explicit error still reports', () async {
      final crash = _FakeCrashReporter();
      final logger = AppLogger(crashReporter: crash, sink: (_) {});

      logger.error('mystery');
      await Future<void>.delayed(Duration.zero);

      expect(crash.errors.single, isA<StateError>());
    });

    test('defaults to a no-op crash reporter', () {
      expect(() => AppLogger().info('ok'), returnsNormally);
    });
  });

  group('NoOpCrashReporter', () {
    test('all methods complete without throwing', () async {
      final reporter = NoOpCrashReporter();
      await reporter.log('x');
      await reporter.recordError(StateError('x'), StackTrace.empty);
      await reporter.setUserId('u');
      await reporter.setCustomKey('k', 1);
    });
  });
}
