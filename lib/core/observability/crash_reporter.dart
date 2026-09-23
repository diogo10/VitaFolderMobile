import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Non-fatal crash reporting contract.
///
/// Production code depends on this interface so unit tests can substitute a
/// no-op or in-memory fake without touching Firebase.
abstract interface class CrashReporter {
  /// Breadcrumb attached to the next crash report. Never throws.
  Future<void> log(String message);

  /// Non-fatal (or fatal, via [fatal]) error report. Never throws.
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, Object?>? context,
    bool fatal = false,
  });

  /// Associates subsequent reports with a user. Never throws.
  Future<void> setUserId(String? userId);

  /// Custom key/value pair on subsequent reports. Never throws.
  Future<void> setCustomKey(String key, Object value);
}

/// Default reporter used before Firebase is ready and in unit tests.
class NoOpCrashReporter implements CrashReporter {
  @override
  Future<void> log(String message) async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, Object?>? context,
    bool fatal = false,
  }) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}
}

/// Firebase Crashlytics implementation.
///
/// All calls are guarded so a Crashlytics outage never crashes the app.
class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  /// Installs the global error handlers that route Flutter framework errors
  /// and uncaught async errors to Crashlytics. Call once after
  /// `Firebase.initializeApp`, before `runApp`.
  static void installGlobalHandlers() {
    final instance = FirebaseCrashlytics.instance;
    FlutterError.onError = instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  @override
  Future<void> log(String message) async {
    try {
      await _crashlytics.log(message);
    } on Object catch (_) {
      // Reporting is best-effort; never disrupt the app.
    }
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, Object?>? context,
    bool fatal = false,
  }) async {
    try {
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
        information: context == null || context.isEmpty
            ? const []
            : [DiagnosticsProperty('', context)],
      );
    } on Object catch (_) {
      // Reporting is best-effort; never disrupt the app.
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    try {
      await _crashlytics.setUserIdentifier(userId ?? '');
    } on Object catch (_) {
      // Reporting is best-effort; never disrupt the app.
    }
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    try {
      await _crashlytics.setCustomKey(key, value);
    } on Object catch (_) {
      // Reporting is best-effort; never disrupt the app.
    }
  }
}
