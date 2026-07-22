import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  bool isLoggedIn() { 
    return Supabase.instance.client.auth.currentUser != null;
  }

  String get currentUserId => Supabase.instance.client.auth.currentUser?.id ?? '';

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

    if (response.user != null && response.user!.email == null) {
       Supabase.instance.client.auth.startAutoRefresh();
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
