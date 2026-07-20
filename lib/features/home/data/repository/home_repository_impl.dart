import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
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
    if (!_authService.isLoggedIn) {
      return Left(NoDataException());
    }

    try {
      final response = await _client.from('profiles').select();
      final people = (response as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (people.isEmpty) {
        return Left(NoDataException());
      }

      final firstPersonName = _extractPersonName(people.first);
      final greeting = firstPersonName.isNotEmpty ? 'Hello $firstPersonName' : 'Hello';
      final message = people.length == 1
          ? 'You have 1 person in your circle.'
          : 'You have ${people.length} people in your circle.';

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
