import 'package:firebase_performance/firebase_performance.dart';

/// Handle for a single in-flight performance trace.
abstract interface class TraceHandle {
  Future<void> putAttribute(String name, String value);
  Future<void> putMetric(String name, int value);
  Future<void> stop();
}

/// Performance tracing contract (Firebase Performance or no-op).
///
/// Production code depends on this interface so unit tests can substitute a
/// fake without touching Firebase.
abstract interface class PerformanceTracer {
  /// Starts [name], runs [action], stops the trace, and returns its result.
  ///
  /// The trace is always stopped, even when [action] throws.
  Future<T> trace<T>(
    String name,
    Future<T> Function(TraceHandle trace) action, {
    Map<String, String>? attributes,
  });

  Future<TraceHandle> startTrace(String name);
}

class _NoOpTraceHandle implements TraceHandle {
  @override
  Future<void> putAttribute(String name, String value) async {}

  @override
  Future<void> putMetric(String name, int value) async {}

  @override
  Future<void> stop() async {}
}

/// Default tracer used in unit tests and before Firebase is ready.
class NoOpPerformanceTracer implements PerformanceTracer {
  @override
  Future<T> trace<T>(
    String name,
    Future<T> Function(TraceHandle trace) action, {
    Map<String, String>? attributes,
  }) {
    return action(_NoOpTraceHandle());
  }

  @override
  Future<TraceHandle> startTrace(String name) async => _NoOpTraceHandle();
}

class _FirebaseTraceHandle implements TraceHandle {
  _FirebaseTraceHandle(this._trace);
  final Trace _trace;

  @override
  Future<void> putAttribute(String name, String value) async {
    try {
      _trace.putAttribute(name, value);
    } on Object catch (_) {
      // Tracing is best-effort; never disrupt the app.
    }
  }

  @override
  Future<void> putMetric(String name, int value) async {
    try {
      _trace.setMetric(name, value);
    } on Object catch (_) {
      // Tracing is best-effort; never disrupt the app.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _trace.stop();
    } on Object catch (_) {
      // Tracing is best-effort; never disrupt the app.
    }
  }
}

/// Firebase Performance implementation. All calls are guarded so a
/// Performance outage never crashes the app.
class FirebasePerformanceTracer implements PerformanceTracer {
  FirebasePerformanceTracer({FirebasePerformance? performance})
    : _performance = performance ?? FirebasePerformance.instance;

  final FirebasePerformance _performance;

  @override
  Future<T> trace<T>(
    String name,
    Future<T> Function(TraceHandle trace) action, {
    Map<String, String>? attributes,
  }) async {
    final handle = await startTrace(name);
    if (attributes != null) {
      for (final entry in attributes.entries) {
        await handle.putAttribute(entry.key, entry.value);
      }
    }
    try {
      return await action(handle);
    } finally {
      await handle.stop();
    }
  }

  @override
  Future<TraceHandle> startTrace(String name) async {
    try {
      final trace = _performance.newTrace(name);
      await trace.start();
      return _FirebaseTraceHandle(trace);
    } on Object catch (_) {
      return _NoOpTraceHandle();
    }
  }
}
