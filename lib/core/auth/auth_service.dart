import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:house_mira/core/auth/auth_state_notifier.dart'
    show AuthStateNotifier;
import 'package:house_mira/core/auth/google_sign_in_handler.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
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
  }) : _client = supabaseClient,
       _googleHandler = googleSignInHandler;

  final SupabaseClient _client;
  final IGoogleSignInHandler _googleHandler;

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
    } on Object catch (e) {
      debugPrint('Error ensuring profile: $e');
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
  /// Google flow. Throws [AuthException] when the ID token is missing or
  /// the exchange fails.
  Future<User?> signInWithGoogle() async {
    final GoogleAuthTokens? tokens;
    try {
      tokens = await _googleHandler.signIn();
    } on GoogleSignInException catch (e) {
      debugPrint(
        '[AuthService] Google sign-in failed '
        '(code: ${e.code.name}, description: ${e.description})',
      );
      throw AuthException(e.description ?? 'Google sign-in failed.');
    }

    if (tokens == null) {
      debugPrint('[AuthService] Google sign-in canceled by the user.');
      return null;
    }

    debugPrint('[AuthService] exchanging Google ID token with Supabase.');
    final AuthResponse response;
    try {
      response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      );
    } on Object catch (e) {
      debugPrint('[AuthService] Supabase ID token exchange failed: $e');
      rethrow;
    }

    if (response.user == null) {
      debugPrint('[AuthService] Supabase exchange returned no user.');
      throw const AuthException('An unexpected error occurred.');
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

    debugPrint(
      '[AuthService] Google sign-in succeeded (${response.user!.id}).',
    );
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
    try {
      await _client.functions.invoke(
        'delete-account',
      );
    } on FunctionException catch (e) {
      throw _mapFunctionException(e);
    }
  }

  Exception _mapFunctionException(FunctionException e) {
    final details = e.details;
    if (e.status == 409 && details is Map && details['code'] == 'sole_owner') {
      final familyId = details['family_id'];
      return SoleOwnerException(
        familyId: familyId is String ? familyId : null,
      );
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
    await _client.auth.updateUser(
      UserAttributes(data: {'full_name': name}),
    );
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
    } on Object catch (e) {
      debugPrint('Error getting the family: $e');
      return null;
    }
  }

  Future<PersonEntity?> getAsPersonEntity() async {
    try {
      final userId = currentUser?.id ?? '';
      final response = await _client.from('profiles').select().eq('id', userId);

      return PersonEntity.from(response.single);
    } on Object catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }
}
