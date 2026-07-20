import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  bool get isLoggedIn => Supabase.instance.client.auth.currentUser != null;

  Stream<AuthState> get onAuthStateChanged =>
      Supabase.instance.client.auth.onAuthStateChange;

  Future<User?> signUp({
    required String email,
    required String password,
  }) async {
    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw AuthException('An unexpected error occurred.');
    }

    
    return response.user;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw AuthException('Invalid email or password.');
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}
