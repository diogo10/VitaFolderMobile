import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:house_mira/core/auth/google_sign_in_handler.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService({
    required SupabaseClient supabaseClient,
    required IGoogleSignInHandler googleSignInHandler,
  }) : _client = supabaseClient,
       _googleHandler = googleSignInHandler;

  final SupabaseClient _client;
  final IGoogleSignInHandler _googleHandler;

  User? get currentUser => _client.auth.currentUser;

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
    );

    if (response.user == null) {
      throw AuthException('An unexpected error occurred.');
    }

    if (response.user != null && response.user!.email == null) {
      _client.auth.startAutoRefresh();
      await _updateUser(name, email);
    }

    return response.user;
  }

  Future<void> _updateUser(String name, String email) async {
    try {
      String userId = currentUser?.id ?? "";
      await _client
          .from('profiles')
          .update({'full_name': name, 'email': email})
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error creating family: $e');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw AuthException('Invalid email or password.');
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
      throw AuthException(e.description ?? 'Google sign-in failed.');
    }

    if (tokens == null) {
      return null;
    }

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: tokens.idToken,
      accessToken: tokens.accessToken,
    );

    if (response.user == null) {
      throw AuthException('An unexpected error occurred.');
    }

    return response.user;
  }

  Future<void> triggerForgetPassword({required String email}) async {
    return _client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await _googleHandler.signOut();
    await _client.auth.signOut();
  }

  // https://supabase.com/docs/guides/auth/passwords?queryGroups=language&language=dart#resetting-a-password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: "http://example.com/account/update-password",
    );
  }

  Future<void> updateName(String name) async {
    final userId = currentUserId;
    if (userId == null) {
      throw AuthException('Not signed in.');
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
    } catch (e) {
      debugPrint('Error getting the family: $e');
      return null;
    }
  }

  Future<PersonEntity?> getAsPersonEntity() async {
    try {
      final userId = currentUser?.id ?? "";
      final response = await _client.from('profiles').select().eq('id', userId);

      return PersonEntity.from(response.single);
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }
}
