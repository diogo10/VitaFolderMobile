import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:house_mira_core/auth/auth_state_notifier.dart'
    show AuthStateNotifier;
import 'package:house_mira_core/auth/google_sign_in_handler.dart';
import 'package:house_mira_core/observability/app_logger.dart';
import 'package:house_mira_core/observability/crash_reporter.dart';
import 'package:house_mira_core/observability/performance_tracer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SoleOwnerException implements Exception {
  SoleOwnerException({this.familyId});

  final String? familyId;
}

/// Thrown when the `delete-account` edge function reports that the
/// account could not be deleted on the server side.
class DeleteAccountException extends AuthException {
  DeleteAccountException(super.message);
}

class AuthService {
  AuthService({
    required SupabaseClient supabaseClient,
    required IGoogleSignInHandler googleSignInHandler,
    CrashReporter? crashReporter,
    AppLogger? logger,
    PerformanceTracer? tracer,
  }) : _client = supabaseClient,
       _googleHandler = googleSignInHandler,
       _logger = logger ?? AppLogger(crashReporter: crashReporter),
       _tracer = tracer ?? NoOpPerformanceTracer();

  final SupabaseClient _client;
  final IGoogleSignInHandler _googleHandler;
  final AppLogger _logger;
  final PerformanceTracer _tracer;

  User? get currentUser => _client.auth.currentUser;

  /// The synchronously recovered session, if session persistence restored
  /// one during `Supabase.initialize`.
  Session? get currentSession => _client.auth.currentSession;

  /// Broadcast of Supabase auth transitions (initial session recovery,
  /// sign-in, sign-out, token refresh). The router observes this via
  /// [AuthStateNotifier] to trigger routing transitions.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  bool isLoggedIn() {
    return _client.auth.currentUser != null;
  }

  /// Whether [error] is an invalid-credentials rejection from Supabase Auth.
  ///
  /// Lets presentation cubits map sign-in failures to typed feedback states
  /// without importing Supabase types themselves.
  bool isInvalidCredentialsError(Object error) => error is AuthApiException;

  /// Whether [error] is any Supabase Auth failure (invalid credentials,
  /// expired/invalid tokens, exchange errors, ...).
  ///
  /// Cubits use this to distinguish expected auth rejections from
  /// unexpected errors without depending on `supabase_flutter` directly.
  bool isAuthError(Object error) => error is AuthException;

  /// Human-readable detail for an auth failure, for logging only.
  ///
  /// Returns the Supabase message when [error] is an auth rejection,
  /// otherwise null. Views show generic localized copy and must never
  /// display this string directly.
  String? authErrorMessage(Object error) =>
      error is AuthException ? error.message : null;

  /// Broadcast of the sign-in state derived from [authStateChanges].
  ///
  /// Emits `true` while a session is active and `false` otherwise, so
  /// presentation cubits can stay in sync with the session without
  /// importing Supabase stream types.
  Stream<bool> get authSignedInChanges =>
      authStateChanges.map((event) => event.session != null);

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );

    if (response.user == null) {
      throw const AuthException('An unexpected error occurred.');
    }

    await _ensureProfile(
      userId: response.user!.id,
      fullName: name,
      email: email,
    );

    return response.user;
  }

  /// Best-effort write of the `profiles` row created by the
  /// `handle_new_user` trigger.
  ///
  /// The trigger inserts the row synchronously with the `auth.users` insert,
  /// but older trigger versions omit `email`/`full_name`. This update fills
  /// the gaps without ever failing sign-up: RLS or network errors are logged
  /// and swallowed so auth always succeeds even if the profile patch fails.
  Future<void> _ensureProfile({
    required String userId,
    String? fullName,
    String? email,
    String? avatarUrl,
  }) async {
    final values = <String, dynamic>{};
    if (fullName != null && fullName.isNotEmpty) values['full_name'] = fullName;
    if (email != null && email.isNotEmpty) values['email'] = email;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      values['avatar_url'] = avatarUrl;
    }
    if (values.isEmpty || userId.isEmpty) return;
    try {
      await _client.from('profiles').update(values).eq('id', userId);
    } on Object catch (e, stackTrace) {
      _logger.warning(
        'ensuring profile failed',
        tag: 'auth',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw const AuthException('Invalid email or password.');
    }
  }

  /// Signs in with Google using the native ID token exchange.
  ///
  /// Retrieves the Google ID token via [IGoogleSignInHandler] and exchanges
  /// it for a Supabase session with `auth.signInWithIdToken`.
  ///
  /// Returns the signed-in [User], or `null` when the user cancels the
  /// Google flow. Throws [AuthException] with an actionable message when
  /// the ID token is missing or the exchange fails. Every failure is
  /// logged (without PII) so Firebase Test Lab / Crashlytics captures the
  /// specific cause while the UI shows a localized, actionable message.
  Future<User?> signInWithGoogle() async {
    final GoogleAuthTokens? tokens;
    try {
      tokens = await _googleHandler.signIn();
    } on GoogleSignInException catch (e, stackTrace) {
      _logger.error(
        'Google sign-in failed',
        tag: 'auth',
        context: {'code': e.code.name},
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthException(
        e.description ?? 'Google sign-in failed. Please try again.',
      );
    } on Object catch (e, stackTrace) {
      _logger.error(
        'Google sign-in failed',
        tag: 'auth',
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthException('Google sign-in failed. Please try again.');
    }

    if (tokens == null) {
      _logger.info('Google sign-in canceled by the user', tag: 'auth');
      return null;
    }

    _logger.debug('exchanging Google ID token with Supabase', tag: 'auth');
    final AuthResponse response;
    try {
      response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      );
    } on AuthException catch (e, stackTrace) {
      _logger.error(
        'Supabase ID token exchange failed',
        tag: 'auth',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } on Object catch (e, stackTrace) {
      _logger.error(
        'Supabase ID token exchange failed',
        tag: 'auth',
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthException('Google sign-in failed. Please try again.');
    }

    if (response.user == null) {
      _logger.error('Supabase exchange returned no user', tag: 'auth');
      throw const AuthException('Google sign-in failed. Please try again.');
    }

    final user = response.user!;
    final metadata = user.userMetadata ?? {};
    await _ensureProfile(
      userId: user.id,
      fullName: metadata['full_name'] as String? ?? metadata['name'] as String?,
      email: user.email,
      avatarUrl:
          metadata['avatar_url'] as String? ?? metadata['picture'] as String?,
    );

    _logger.info('Google sign-in succeeded', tag: 'auth');
    return response.user;
  }

  Future<void> triggerForgetPassword({required String email}) async {
    return _client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await _googleHandler.signOut();
    await _client.auth.signOut();
  }

  /// Permanently deletes the current user's account.
  ///
  /// Invokes the `delete-account` edge function, which verifies the
  /// caller's JWT server-side and deletes the auth user with admin
  /// privileges. Postgres `ON DELETE CASCADE` then removes the
  /// `profiles` row, `family_memberships` rows and notification rows,
  /// while the shared `families` row is left intact.
  ///
  /// Throws [SoleOwnerException] when the user is the last remaining
  /// member of an owned family (nothing is deleted), or
  /// [DeleteAccountException] when the server reports a failure.
  /// Endpoint: `POST /functions/v1/delete-account` on the linked project
  /// (VitaFolderMobileBackend). The client resolves the full URL from
  /// `Supabase.initialize`; the caller JWT is attached automatically and
  /// the uid is taken from the verified token server-side, never the body.
  Future<void> deleteAccount() async {
    if (currentUserId == null) {
      throw const AuthException('Not signed in.');
    }
    const context = <String, Object?>{'function': 'delete-account'};
    _logger.debug('invoking edge function', tag: 'edge', context: context);
    try {
      await _tracer.trace('edge-invoke-delete-account', (trace) async {
        await _client.functions.invoke('delete-account');
        await trace.putAttribute('success', 'true');
      }, attributes: {'function': 'delete-account'});
      _logger.info(
        'edge function completed',
        tag: 'edge',
        context: {...context, 'success': true},
      );
    } on FunctionException catch (e, stackTrace) {
      final mapped = _mapFunctionException(e);
      // Expected rejections (not signed in, sole owner) are control flow;
      // only unexpected server failures become non-fatal crash reports.
      if (mapped is DeleteAccountException) {
        _logger.error(
          'edge function failed',
          tag: 'edge',
          context: {...context, 'status': e.status},
          error: e,
          stackTrace: stackTrace,
        );
      } else {
        _logger.info(
          'edge function rejected',
          tag: 'edge',
          context: {...context, 'status': e.status},
        );
      }
      throw mapped;
    } on Object catch (error, stackTrace) {
      _logger.error(
        'edge function failed',
        tag: 'edge',
        context: context,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Exception _mapFunctionException(FunctionException e) {
    final details = e.details;
    if (e.status == 409 && details is Map && details['code'] == 'sole_owner') {
      final familyId = details['family_id'];
      return SoleOwnerException(familyId: familyId is String ? familyId : null);
    }
    if (e.status == 401) {
      return const AuthException('Not signed in.');
    }
    return DeleteAccountException(
      'Account deletion failed (status ${e.status}).',
    );
  }

  // https://supabase.com/docs/guides/auth/passwords?queryGroups=language&language=dart#resetting-a-password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'http://example.com/account/update-password',
    );
  }

  Future<void> updateName(String name) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const AuthException('Not signed in.');
    }
    await _client.from('profiles').update({'full_name': name}).eq('id', userId);
    await _client.auth.updateUser(UserAttributes(data: {'full_name': name}));
  }

  Future<String?> getProfileName() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        return null;
      }
      final response = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', userId);

      return response.single['full_name'] as String?;
    } on Object catch (e, stackTrace) {
      _logger.warning(
        'getting profile name failed',
        tag: 'auth',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Current user's profile as plain core data (no feature imports).
  ///
  /// Returns the display name and email for the signed-in user, or null
  /// when signed out or the lookup fails. Feature code maps this to its
  /// own entities (e.g. people builds a [PersonEntity]-equivalent view);
  /// core never imports feature domains.
  Future<({String? name, String? email})?> getCurrentProfile() async {
    try {
      final userId = currentUser?.id ?? '';
      if (userId.isEmpty) {
        return null;
      }
      final response = await _client
          .from('profiles')
          .select()
          .eq(
            'id',
            userId,
          );
      final row = response.single as Map;
      final name = row['full_name'] as String?;
      final email = (row['email'] as String?) ?? currentUser?.email;
      return (name: name, email: email);
    } on Object catch (e, stackTrace) {
      _logger.warning(
        'resolving current profile failed',
        tag: 'auth',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
