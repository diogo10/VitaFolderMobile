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
  Future<FamilyEntity?> getFamilyBy(String id) async {
    try {
      final response = await _client.from('families').select().eq('id', id);

      if (response.isEmpty) {
        return null;
      }

      final body = response.single;
      return FamilyEntity(name: body['name'], inviteCode: body['invite_code']);
    } catch (e) {
      debugPrint('Error getting the family: $e');
      return null;
    }
  }

  @override
  Future<Either<Exception, FamilyEntity>> getMyFamily() async {
    try {
      final userId = _authService.currentUserId;
      final response = await _client
          .from('family_memberships')
          .select()
          .eq('user_id', userId);

      if (response.isEmpty) {
        return Left(Exception('No families found'));
      }

      final body = response.single;
      final familyId = body['family_id'];
      final family = await getFamilyBy(familyId);
      return family != null
          ? Right(family)
          : Left(Exception("No families found"));
    } catch (e) {
      debugPrint('Error getting the family: $e');
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, bool>> createFamily({
    required String name,
    required String inviteCode,
  }) async {
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
  Future<Either<Exception, bool>> joinFamily({
    required String inviteCode,
  }) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        throw Exception('Not signed in (no session).');
      }
      debugPrint('access token present: ${session.accessToken.isNotEmpty}');

      final response = await _client
          .from('families')
          .select('id')
          .eq('invite_code', inviteCode);

      if (response.isEmpty) {
        return Left(Exception('Family not found with this invite code'));
      }

      final userId = _authService.currentUserId;
      final familyId = response.single['id'];
      await _client.from('family_memberships').insert({
        'family_id': familyId,
        'user_id': userId,
        "role": 'member',
      });

      // Add to people table
      final userName = await _authService.getProfileName();
      await _client.from('people').insert({
        'family_id': familyId,
        'full_name': userName ?? "",
      });

      return Right(true);
    } catch (e) {
      debugPrint('Error joining family: $e');
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, List<PersonEntity>>> getPeople() async {
    try {
      final userId = _authService.currentUserId;
      final response = await getFamilyIdsForUser(userId);

      if (response.isEmpty) {
        return Left(Exception('No families found'));
      }

      final familyId = response.first;
      final people = await getProfilesWithRoleForFamily(familyId);
      return Right(people);
    } catch (e) {
      debugPrint('Error getting the family: $e');
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<List<String>> getFamilyIdsForUser(String userId) async {
    final res = await _client
        .from('family_memberships')
        .select('family_id')
        .eq('user_id', userId);

    final rows = res as List;
    return rows.map((e) => e['family_id'] as String).toList();
  }

  @override
  Future<List<String>> getMyFamilyRole() async {
    final userId = _authService.currentUserId;
    final res = await _client
        .from('family_memberships')
        .select('role')
        .eq('user_id', userId);

    final rows = res as List;
    return rows.map((e) => e['role'] as String).toList();
  }

  @override
  Future<List<PersonEntity>> getProfilesWithRoleForFamily(
    String familyId,
  ) async {
    //TODO: replace this with a edge function

    // Step 1: get memberships (user_id + role) for the family
    final membershipsRes = await _client
        .from('family_memberships')
        .select('user_id, role')
        .eq('family_id', familyId);

    final memberships = (membershipsRes as List)
        .map((e) => {'user_id': e['user_id'], 'role': e['role']})
        .toList();

    final userIds = memberships.map((m) => m['user_id'] as String).toList();
    if (userIds.isEmpty) return [];

    // Step 2: fetch profiles for those user_ids
    final profilesRes = await _client
        .from('profiles')
        .select()
        .inFilter('id', userIds);

    final profiles = (profilesRes as List);

    // Step 3: merge role back into each profile (matches the original SELECT)
    final roleByUserId = {for (final m in memberships) m['user_id']: m['role']};

    return profiles
        .map((p) {
          final person = PersonEntity.from(p);
          final role = roleByUserId[person?.id];
          return person?.copyWith(role: role);
        })
        .nonNulls
        .toList();
  }
}
