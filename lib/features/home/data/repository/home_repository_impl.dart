import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/features/home/domain/entities/home_entity.dart';
import 'package:vita_folder_mobile/features/home/domain/repository/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final SupabaseClient _client;
  final AuthService _authService;

  HomeRepositoryImpl({SupabaseClient? client, AuthService? authService})
    : _client = client ?? Supabase.instance.client,
      _authService = authService ?? AuthService();

  @override
  Future<Either<Exception, HomeEntity>> getHomeData() async {
    if (!_authService.isLoggedIn()) {
      return Left(NoDataException());
    }

    try {
      final firstPersonName = await getProfile() ?? '';
      final greeting = firstPersonName.isNotEmpty
          ? 'Hello $firstPersonName'
          : 'Hello';
      final message = 'You have 0 people in your circle.';

      return Right(
        HomeEntity(
          greeting: greeting,
          date: DateTime.now().toIso8601String(),
          message: message,
        ),
      );
    } catch (error) {
      return Left(Exception('Failed to load home data: $error'));
    }
  }

  Future<String?> getProfile() async {
    try {
      final response = await _client.schema("public")
          .from('profiles')
          .select('*')
          .eq('id', _authService.currentUserId)
          .single();
      return _extractPersonName(response);
    } catch (error) {
      debugPrint('${_authService.currentUserId} Error fetching profile: $error');
      return null;
    }
  }

  String _extractPersonName(Map<String, dynamic> person) {
    final keys = ['name', 'full_name', 'fullName', 'first_name', 'firstName'];

    for (final key in keys) {
      final value = person[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return '';
  }
}
