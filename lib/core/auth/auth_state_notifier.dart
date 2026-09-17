import 'dart:async';

import 'package:flutter/foundation.dart';
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
  }) : _session = initialSession {
    final stream = authStateStream;
    if (stream == null) {
      _isInitialized = true;
    } else {
      _subscription = stream.listen(_onAuthState);
    }
  }

  /// Creates a notifier wired to a live Supabase client.
  factory AuthStateNotifier.fromSupabase(SupabaseClient client) {
    return AuthStateNotifier(
      authStateStream: client.auth.onAuthStateChange,
      initialSession: client.auth.currentSession,
    );
  }

  Session? _session;
  bool _isInitialized = false;
  StreamSubscription<AuthState>? _subscription;

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
    _session = state.session;
    _isInitialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
