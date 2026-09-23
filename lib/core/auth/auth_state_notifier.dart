import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart' show GoRouter;
import 'package:house_mira/core/observability/app_logger.dart';
import 'package:house_mira/core/observability/crash_reporter.dart';
import 'package:house_mira/core/observability/performance_tracer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reactive bridge between Supabase auth and the [GoRouter] configuration.
///
/// Subscribes to `SupabaseClient.auth.onAuthStateChange` so every auth
/// transition (session recovery on restart, sign-in, sign-out, token refresh)
/// notifies listeners and lets `AppRouter` re-evaluate its redirect logic.
///
/// Session persistence itself is handled by the Supabase SDK, which restores
/// the stored session during `Supabase.initialize` and replays it as an
/// [AuthChangeEvent.initialSession] event. This notifier stays
/// uninitialized ([isInitialized] == false) until that first event arrives,
/// so the router can hold the UI on the splash screen instead of flashing
/// unauthenticated content (FOUNC) while recovery is still in flight.
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier({
    Stream<AuthState>? authStateStream,
    Session? initialSession,
    CrashReporter? crashReporter,
    AppLogger? logger,
    PerformanceTracer? tracer,
  }) : _session = initialSession,
       _crashReporter = crashReporter ?? NoOpCrashReporter(),
       _logger = logger ?? AppLogger(crashReporter: crashReporter),
       _tracer = tracer ?? NoOpPerformanceTracer() {
    final stream = authStateStream;
    if (stream == null) {
      _isInitialized = true;
    } else {
      _recoveryStopwatch.start();
      _subscription = stream.listen(
        _onAuthState,
        onError: _onAuthStateError,
      );
    }
  }

  /// Creates a notifier wired to a live Supabase client.
  factory AuthStateNotifier.fromSupabase(
    SupabaseClient client, {
    CrashReporter? crashReporter,
    AppLogger? logger,
    PerformanceTracer? tracer,
  }) {
    return AuthStateNotifier(
      authStateStream: client.auth.onAuthStateChange,
      initialSession: client.auth.currentSession,
      crashReporter: crashReporter,
      logger: logger,
      tracer: tracer,
    );
  }

  Session? _session;
  bool _isInitialized = false;
  StreamSubscription<AuthState>? _subscription;
  final CrashReporter _crashReporter;
  final AppLogger _logger;
  final PerformanceTracer _tracer;
  final Stopwatch _recoveryStopwatch = Stopwatch();
  bool _recoveryReported = false;

  /// Whether the initial session recovery round-trip has completed.
  ///
  /// False from construction until the first `onAuthStateChange` event
  /// (typically [AuthChangeEvent.initialSession]) is received.
  bool get isInitialized => _isInitialized;

  /// Whether a session is currently active (i.e. the user is signed in).
  ///
  /// Reads the last session delivered by `onAuthStateChange`, falling back
  /// to the synchronously recovered `currentSession` before the first event.
  bool get isAuthenticated => _session != null;

  /// The last known session, or null when signed out.
  Session? get session => _session;

  void _onAuthState(AuthState state) {
    final isFirstEvent = !_isInitialized;
    _session = state.session;
    _isInitialized = true;
    if (isFirstEvent && !_recoveryReported) {
      _recoveryReported = true;
      if (_recoveryStopwatch.isRunning) {
        _recoveryStopwatch.stop();
      }
      unawaited(
        () async {
          try {
            await _reportSessionRecovery(state);
          } on Object catch (error, stackTrace) {
            _logger.error(
              'session recovery reporting failed',
              tag: 'auth',
              error: error,
              stackTrace: stackTrace,
            );
          }
        }(),
      );
    } else {
      _logger.debug(
        'auth transition',
        tag: 'auth',
        context: {
          'event': state.event.name,
          'signed_in': state.session != null,
        },
      );
    }
    notifyListeners();
  }

  /// Times the initial-session recovery round-trip so slow or failing
  /// restores show up in Performance + Crashlytics instead of silently
  /// holding the splash gate.
  Future<void> _reportSessionRecovery(AuthState state) async {
    final elapsedMs = _recoveryStopwatch.elapsedMilliseconds;
    final hasSession = state.session != null;
    await _tracer.trace(
      'auth-session-recovery',
      (trace) async {
        await trace.putAttribute('event', state.event.name);
        await trace.putAttribute('has_session', '$hasSession');
        await trace.putMetric('recovery_ms', elapsedMs);
      },
    );
    unawaited(_crashReporter.setCustomKey('auth_recovery_ms', elapsedMs));
    if (elapsedMs > 5000) {
      _logger.warning(
        'slow session recovery',
        tag: 'auth',
        context: {
          'event': state.event.name,
          'recovery_ms': elapsedMs,
          'has_session': hasSession,
        },
      );
    } else {
      _logger.info(
        'session recovery completed',
        tag: 'auth',
        context: {
          'event': state.event.name,
          'recovery_ms': elapsedMs,
          'has_session': hasSession,
        },
      );
    }
    String? userId;
    try {
      userId = state.session?.user.id;
    } on Object catch (_) {
      // A session that cannot expose its user id must not break recovery
      // reporting; the trace and log above already captured the outcome.
      userId = null;
    }
    if (userId != null) {
      unawaited(_crashReporter.setUserId(userId));
    }
  }

  /// A failing auth stream must never wedge the router on the splash screen
  /// silently: report it and unblock initialization as signed out.
  void _onAuthStateError(Object error, StackTrace stackTrace) {
    _logger.error(
      'auth state stream failed',
      tag: 'auth',
      error: error,
      stackTrace: stackTrace,
    );
    if (!_isInitialized) {
      _isInitialized = true;
      if (_recoveryStopwatch.isRunning) {
        _recoveryStopwatch.stop();
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
