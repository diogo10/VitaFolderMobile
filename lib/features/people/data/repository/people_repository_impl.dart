import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/family_entity.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/person_entity.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';

class PeopleRepositoryImpl implements PeopleRepository {
  final SupabaseClient _client;
  final AuthService _authService;

  PeopleRepositoryImpl({SupabaseClient? client, AuthService? authService})
    : _client = client ?? Supabase.instance.client,
      _authService = authService ?? AuthService();


  @override
  Future<Either<Exception, FamilyEntity>> getFamily() async {
    try {
      final userId = _authService.currentUserId;
      final response = await _client
          .from('families')
          .select()
          .eq('created_by', userId);

      if (response.isEmpty) {
        return Left(Exception('No families found'));
      }

      
      final body = response.single;
      final families = FamilyEntity(
          name: body['name'],
          inviteCode: body['invite_code'],
        );
      return Right(families);
    } catch (e) {
      debugPrint('Error getting the family: $e');
      return Left(Exception(e.toString()));
    }
  }      

  @override
  Future<Either<Exception, bool>> createFamily({required String name, required String inviteCode}) async {
    try {
      final userId = _authService.currentUserId;
      await _client.from('families').insert({
        'name': name,
        'created_by': userId,
        'country_code': 'PT',
        'invite_code': inviteCode,
      });

      return Right(true);
    } catch (e) {
      debugPrint('Error creating family: $e');
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, List<PersonEntity>>> getPeople() async {
    try {
      final userId = _authService.currentUserId;
      final response = await _client
          .from('families')
          .select()
          .eq('created_by', userId);

      if (response.isEmpty) {
        return Left(Exception('No families found'));
      }

      final List<PersonEntity> people = response.map<PersonEntity>((family) {
        return PersonEntity(
          id: family['id'],
          name: family['name'],
          phone: "",
          email: family['email'],
        );
      }).toList();
      return Right(people);
    } catch (e) {
      debugPrint('Error getting the family: $e');
      return Left(Exception(e.toString()));
    }
  }
}
