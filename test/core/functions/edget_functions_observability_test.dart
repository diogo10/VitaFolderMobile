import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/functions/edget_functions.dart';
import 'package:house_mira/core/observability/app_logger.dart';
import 'package:house_mira/core/observability/crash_reporter.dart';
import 'package:house_mira/core/observability/performance_tracer.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockFunctionsClient extends Mock implements FunctionsClient {}

class _RecordingCrashReporter implements CrashReporter {
  final logs = <String>[];
  final errors = <Object>[];
  final reasons = <String?>[];

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
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}
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
  late _MockSupabaseClient supabase;
  late _MockFunctionsClient functions;
  late _RecordingCrashReporter crash;
  late _RecordingTraceHandle handle;
  late _RecordingTracer tracer;
  late List<String> lines;

  setUp(() {
    supabase = _MockSupabaseClient();
    functions = _MockFunctionsClient();
    crash = _RecordingCrashReporter();
    handle = _RecordingTraceHandle();
    tracer = _RecordingTracer(handle);
    lines = <String>[];
    when(() => supabase.functions).thenReturn(functions);
  });

  EdgetFunctions build() => EdgetFunctions(
    supabaseClient: supabase,
    crashReporter: crash,
    logger: AppLogger(crashReporter: crash, sink: lines.add),
    tracer: tracer,
  );

  group('EdgetFunctions observability', () {
    test('successful invoke is traced with status and success', () async {
      when(
        () => functions.invoke(any(), body: any(named: 'body')),
      ).thenAnswer(
        (_) async => const FunctionResponse(
          data: {'success': true},
          status: 200,
        ),
      );

      expect(
        await build().sendEmail(to: 'a@b.c', subject: 'Invite'),
        isTrue,
      );
      await Future<void>.delayed(Duration.zero);

      expect(tracer.names, ['edge-invoke-resend-email-v1']);
      expect(handle.attributes['success'], 'true');
      expect(handle.metrics['status'], 200);
      expect(handle.stops, 1);
      expect(crash.errors, isEmpty);
      expect(lines.any((l) => l.contains('edge function completed')), isTrue);
      // No PII in logs or breadcrumbs.
      expect(lines.join().contains('a@b.c'), isFalse);
    });

    test('failed invoke is reported and rethrown', () async {
      when(
        () => functions.invoke(any(), body: any(named: 'body')),
      ).thenThrow(
        const FunctionException(status: 502, reasonPhrase: 'relay down'),
      );

      await expectLater(
        () => build().sendEmail(to: 'a@b.c', subject: 'Invite'),
        throwsA(isA<FunctionException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(tracer.names, ['edge-invoke-resend-email-v1']);
      expect(handle.stops, 1);
      expect(crash.errors.single, isA<FunctionException>());
      expect(crash.logs.single, contains('[error][edge] edge function failed'));
    });
  });
}
