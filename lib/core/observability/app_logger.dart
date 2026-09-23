import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:house_mira/core/observability/crash_reporter.dart';

/// Log severity for structured application logs.
enum AppLogLevel { debug, info, warning, error }

/// Structured logger shared by all features.
///
/// Emits human-readable lines via [debugPrint] in debug builds and forwards
/// warnings/errors to [CrashReporter] so production failures stay visible in
/// Crashlytics. Context maps must never contain PII (no emails, tokens, or
/// raw payloads) — log ids and counts instead.
class AppLogger {
  AppLogger({CrashReporter? crashReporter, void Function(String line)? sink})
    : _crashReporter = crashReporter ?? NoOpCrashReporter(),
      _sink = sink ?? debugPrint;

  final CrashReporter _crashReporter;
  final void Function(String line) _sink;

  void debug(
    String message, {
    String? tag,
    Map<String, Object?>? context,
  }) {
    _emit(AppLogLevel.debug, message, tag: tag, context: context);
  }

  void info(
    String message, {
    String? tag,
    Map<String, Object?>? context,
  }) {
    _emit(AppLogLevel.info, message, tag: tag, context: context);
  }

  void warning(
    String message, {
    String? tag,
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _emit(
      AppLogLevel.warning,
      message,
      tag: tag,
      context: context,
      error: error,
    );
    unawaited(
      _crashReporter.log(
        _format(AppLogLevel.warning, message, tag: tag, context: context),
      ),
    );
    if (error != null) {
      unawaited(
        _crashReporter.recordError(
          error,
          stackTrace ?? StackTrace.current,
          reason: _format(AppLogLevel.warning, message, tag: tag),
          context: context,
        ),
      );
    }
  }

  void error(
    String message, {
    String? tag,
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _emit(
      AppLogLevel.error,
      message,
      tag: tag,
      context: context,
      error: error,
    );
    unawaited(
      _crashReporter.log(
        _format(AppLogLevel.error, message, tag: tag, context: context),
      ),
    );
    unawaited(
      _crashReporter.recordError(
        error ?? StateError(message),
        stackTrace ?? StackTrace.current,
        reason: _format(AppLogLevel.error, message, tag: tag),
        context: context,
      ),
    );
  }

  void _emit(
    AppLogLevel level,
    String message, {
    String? tag,
    Map<String, Object?>? context,
    Object? error,
  }) {
    if (!kDebugMode) return;
    final line = _format(level, message, tag: tag, context: context);
    _sink(error == null ? line : '$line error=$error');
  }

  static String _format(
    AppLogLevel level,
    String message, {
    String? tag,
    Map<String, Object?>? context,
  }) {
    final scope = tag == null || tag.isEmpty ? 'app' : tag;
    final ctx = context == null || context.isEmpty ? '' : ' $context';
    return '[${level.name}][$scope] $message$ctx';
  }
}
