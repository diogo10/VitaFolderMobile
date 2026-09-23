import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/auth/auth_state_notifier.dart';
import 'package:house_mira/core/observability/app_logger.dart';
import 'package:house_mira/core/observability/crash_reporter.dart';
import 'package:house_mira/core/observability/performance_tracer.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSession extends Mock implements Session {}

class _MockUser extends Mock implements User {}

class _RecordingCrashReporter implements CrashReporter {
  final logs = <String>[];
  final errors = <Object>[];
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

class _RecordingTraceHandle implements TraceHandle {
  final attributes = <String, String>{};
  final metrics = <String, int>{};
  var stops = 0;

  @override
  Future<void> putAttribute(String name, String value) async {
    attributes[name] = value;
  }

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
  group('AuthStateNotifier observability', () {
    test('initial session recovery is traced and attributed', () async {
      final controller = StreamController<AuthState>.broadcast();
      final crash = _RecordingCrashReporter();
      final handle = _RecordingTraceHandle();
      final tracer = _RecordingTracer(handle);
      final lines = <String>[];
      final notifier = AuthStateNotifier(
        authStateStream: controller.stream,
        crashReporter: crash,
        logger: AppLogger(crashReporter: crash, sink: lines.add),
        tracer: tracer,
      );
      addTearDown(() async {
        notifier.dispose();
        await controller.close();
      });

      final session = _MockSession();
      final user = _MockUser();
      when(() => user.id).thenReturn('user-1');
      when(() => session.user).thenReturn(user);
      controller.add(AuthState(AuthChangeEvent.initialSession, session));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.isInitialized, isTrue);
      expect(tracer.names, ['auth-session-recovery']);
      expect(handle.attributes['event'], 'initialSession');
      expect(handle.attributes['has_session'], 'true');
      expect(handle.metrics['recovery_ms'], isA<int>());
      expect(handle.stops, 1);
      expect(crash.keys['auth_recovery_ms'], isA<int>());
      expect(crash.userIds, ['user-1']);
      expect(lines.single, contains('session recovery completed'));
    });

    test('signed-out recovery traces without a user id', () async {
      final controller = StreamController<AuthState>.broadcast();
      final crash = _RecordingCrashReporter();
      final handle = _RecordingTraceHandle();
      final notifier = AuthStateNotifier(
        authStateStream: controller.stream,
        crashReporter: crash,
        tracer: _RecordingTracer(handle),
      );
      addTearDown(() async {
        notifier.dispose();
        await controller.close();
      });

      controller.add(const AuthState(AuthChangeEvent.initialSession, null));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.isInitialized, isTrue);
      expect(notifier.isAuthenticated, isFalse);
      expect(handle.attributes['has_session'], 'false');
      expect(crash.userIds, isEmpty);
    });

    test('stream errors are reported and unblock initialization', () async {
      final controller = StreamController<AuthState>.broadcast();
      final crash = _RecordingCrashReporter();
      final notifier = AuthStateNotifier(
        authStateStream: controller.stream,
        crashReporter: crash,
      );
      addTearDown(() async {
        notifier.dispose();
        await controller.close();
      });

      controller.addError(Exception('auth stream down'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.isInitialized, isTrue);
      expect(notifier.isAuthenticated, isFalse);
      expect(crash.errors.single, isA<Exception>());
      expect(
        crash.logs.single,
        contains('[error][auth] auth state stream failed'),
      );
    });

    test('later transitions log at debug level without extra traces', () async {
      final controller = StreamController<AuthState>.broadcast();
      final handle = _RecordingTraceHandle();
      final tracer = _RecordingTracer(handle);
      final lines = <String>[];
      final crash = _RecordingCrashReporter();
      final notifier = AuthStateNotifier(
        authStateStream: controller.stream,
        crashReporter: crash,
        logger: AppLogger(crashReporter: crash, sink: lines.add),
        tracer: tracer,
      );
      addTearDown(() async {
        notifier.dispose();
        await controller.close();
      });

      controller.add(const AuthState(AuthChangeEvent.initialSession, null));
      await Future<void>.delayed(Duration.zero);
      controller.add(const AuthState(AuthChangeEvent.signedOut, null));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(tracer.names, ['auth-session-recovery']);
      expect(lines.any((l) => l.contains('auth transition')), isTrue);
    });
  });
}
