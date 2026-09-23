import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/auth/google_sign_in_handler.dart';
import 'package:house_mira/core/observability/app_logger.dart';
import 'package:house_mira/core/observability/crash_reporter.dart';
import 'package:house_mira/core/observability/performance_tracer.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockGoogleSignInHandler extends Mock implements IGoogleSignInHandler {}

class _MockFunctionsClient extends Mock implements FunctionsClient {}

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
  final attributes = <String, String>{};
  var stops = 0;

  @override
  Future<void> putAttribute(String name, String value) async {
    attributes[name] = value;
  }

  @override
  Future<void> putMetric(String name, int value) async {}

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

User _user({String id = 'u1'}) {
  final user = User.fromJson({'id': id, 'email': 'a@b.c'});
  if (user == null) throw StateError('Failed to build test user');
  return user;
}

void main() {
  late _MockSupabaseClient supabase;
  late _MockGoTrueClient auth;
  late _MockGoogleSignInHandler googleHandler;
  late _MockFunctionsClient functions;
  late _RecordingCrashReporter crash;
  late _RecordingTraceHandle handle;
  late _RecordingTracer tracer;
  late List<String> lines;

  setUp(() {
    supabase = _MockSupabaseClient();
    auth = _MockGoTrueClient();
    googleHandler = _MockGoogleSignInHandler();
    functions = _MockFunctionsClient();
    crash = _RecordingCrashReporter();
    handle = _RecordingTraceHandle();
    tracer = _RecordingTracer(handle);
    lines = <String>[];
    when(() => supabase.auth).thenReturn(auth);
    when(() => supabase.functions).thenReturn(functions);
  });

  AuthService build() => AuthService(
    supabaseClient: supabase,
    googleSignInHandler: googleHandler,
    crashReporter: crash,
    logger: AppLogger(crashReporter: crash, sink: lines.add),
    tracer: tracer,
  );

  group('AuthService.deleteAccount observability', () {
    test('successful invoke is traced', () async {
      when(() => auth.currentUser).thenReturn(_user());
      when(() => functions.invoke(any())).thenAnswer(
        (_) async => const FunctionResponse(
          data: {'success': true},
          status: 200,
        ),
      );

      await build().deleteAccount();
      await Future<void>.delayed(Duration.zero);

      expect(tracer.names, ['edge-invoke-delete-account']);
      expect(handle.attributes['success'], 'true');
      expect(handle.stops, 1);
      expect(crash.errors, isEmpty);
      expect(lines.any((l) => l.contains('edge function completed')), isTrue);
    });

    test('server failure maps and is reported as non-fatal', () async {
      when(() => auth.currentUser).thenReturn(_user());
      when(() => functions.invoke(any())).thenThrow(
        const FunctionException(
          status: 500,
          details: {'code': 'delete_failed'},
        ),
      );

      await expectLater(
        () => build().deleteAccount(),
        throwsA(isA<DeleteAccountException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(crash.errors.single, isA<FunctionException>());
      expect(crash.logs.single, contains('[error][edge] edge function failed'));
    });

    test(
      'expected sole-owner rejection is logged, not crash-reported',
      () async {
        when(() => auth.currentUser).thenReturn(_user());
        when(() => functions.invoke(any())).thenThrow(
          const FunctionException(
            status: 409,
            details: {'code': 'sole_owner', 'family_id': 'family-1'},
          ),
        );

        await expectLater(
          () => build().deleteAccount(),
          throwsA(isA<SoleOwnerException>()),
        );
        await Future<void>.delayed(Duration.zero);

        expect(crash.errors, isEmpty);
        expect(lines.any((l) => l.contains('edge function rejected')), isTrue);
      },
    );

    test('unexpected invoke errors are reported and rethrown', () async {
      when(() => auth.currentUser).thenReturn(_user());
      when(() => functions.invoke(any())).thenThrow(Exception('Network down'));

      await expectLater(() => build().deleteAccount(), throwsException);
      await Future<void>.delayed(Duration.zero);

      expect(crash.errors.single, isA<Exception>());
    });
  });
}
