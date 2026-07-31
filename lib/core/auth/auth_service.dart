import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/person_entity.dart';

class AuthService {
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  bool isLoggedIn() {
    return Supabase.instance.client.auth.currentUser != null;
  }

  String get currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
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
      await _updateUser(name, email);
    }

    return response.user;
  }

  Future<void> _updateUser(String name, String email) async {
    try {
      String userId = currentUser?.id ?? "";
      await Supabase.instance.client
          .from('profiles')
          .update({'full_name': name, 'email': email})
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error creating family: $e');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw AuthException('Invalid email or password.');
    }
  }

  Future<void> triggerForgetPassword({required String email}) async {
    return Supabase.instance.client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  // https://supabase.com/docs/guides/auth/passwords?queryGroups=language&language=dart#resetting-a-password
  Future<void> resetPassword(String email) async {
    await Supabase.instance.client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: "http://example.com/account/update-password",
    );
  }

  Future<void> updateName(String name) async {
    final userId = currentUserId;
    await Supabase.instance.client
        .from('profiles')
        .update({'full_name': name})
        .eq('id', userId);
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(data: {'full_name': name}),
    );
  }

  Future<String?> getProfileName() async {
    try {
      final userId = currentUserId;
      final response = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', userId);

      return response.single['full_name'];
    } catch (e) {
      debugPrint('Error getting the family: $e');
      return null;
    }
  }

  Future<PersonEntity?> getAsPersonEntity() async {
    try {
      final userId = currentUser?.id ?? "";
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId);

      return PersonEntity.from(response.single);
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }
}
