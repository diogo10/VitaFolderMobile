import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira_core/auth/auth_service.dart';
import 'package:house_mira_people/domain/entities/family_entity.dart';
import 'package:house_mira_people/domain/entities/person_entity.dart';
import 'package:house_mira_people/domain/invite_code.dart';
import 'package:house_mira_people/domain/repository/people_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PeopleRepositoryImpl implements PeopleRepository {
  PeopleRepositoryImpl({
    required AuthService authService,
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client,
       _authService = authService;
  final SupabaseClient _client;
  final AuthService _authService;

  @override
  Future<FamilyEntity?> getFamilyBy(String id) async {
    try {
      final response = await _client.from('families').select().eq('id', id);

      if (response.isEmpty) {
        return null;
      }

      final body = response.single;
      return FamilyEntity(
        name: body['name'] as String,
        inviteCode: body['invite_code'] as String,
      );
    } on Object catch (e) {
      debugPrint('Error getting the family: $e');
      return null;
    }
  }

  @override
  Future<Either<Exception, FamilyEntity>> getMyFamily() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        return Left(Exception('Not signed in.'));
      }
      final response = await _client
          .from('family_memberships')
          .select()
          .eq('user_id', userId);

      if (response.isEmpty) {
        return Left(Exception('No families found'));
      }

      final body = response.single;
      final familyId = body['family_id'] as String;
      final family = await getFamilyBy(familyId);
      return family != null
          ? Right(family)
          : Left(Exception('No families found'));
    } on Object catch (e) {
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
      if (userId == null) {
        return Left(Exception('Not signed in.'));
      }
      await _client.from('families').insert({
        'name': name,
        'created_by': userId,
        'country_code': 'PT',
        'invite_code': inviteCode,
      });

      return const Right(true);
    } on Object catch (e) {
      debugPrint('Error creating family: $e');
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, bool>> joinFamily({
    required String inviteCode,
  }) async {
    try {
      final code = normalizeInviteCode(inviteCode);
      if (!isValidInviteCode(code)) {
        return Left(Exception('Invalid family code'));
      }
      final session = _client.auth.currentSession;
      if (session == null) {
        throw Exception('Not signed in (no session).');
      }
      debugPrint('access token present: ${session.accessToken.isNotEmpty}');

      final response = await _client
          .from('families')
          .select('id')
          .eq('invite_code', code);

      if (response.isEmpty) {
        return Left(Exception('Family not found with this invite code'));
      }

      final userId = _authService.currentUserId;
      if (userId == null) {
        throw Exception('Not signed in (no user id).');
      }
      final familyId = response.single['id'] as String;

      // Idempotent join: a retry (double tap, or a previous attempt that
      // failed after the membership row was written) must succeed instead
      // of surfacing a duplicate-key error as an invalid code.
      if (!await _isMemberOf(userId, familyId)) {
        try {
          await _client.from('family_memberships').insert({
            'family_id': familyId,
            'user_id': userId,
            'role': 'member',
          });
        } on Object catch (_) {
          // Lost race / duplicate insert (e.g. double tap): re-check.
          if (!await _isMemberOf(userId, familyId)) {
            rethrow;
          }
        }
      }

      // Best-effort people row: a failure here must never report the join
      // itself as failed — the membership above is what makes the user
      // part of the family.
      try {
        final userName = await _authService.getProfileName();
        await _client.from('people').insert({
          'family_id': familyId,
          'full_name': userName ?? '',
        });
      } on Object catch (e) {
        debugPrint('Non-fatal: could not add person row after join: $e');
      }

      return const Right(true);
    } on Object catch (e) {
      debugPrint('Error joining family: $e');
      return Left(Exception(e.toString()));
    }
  }

  Future<bool> _isMemberOf(String userId, String familyId) async {
    final rows = await _client
        .from('family_memberships')
        .select('family_id')
        .eq('user_id', userId);
    return (rows as List).any(
      (row) => (row as Map<String, dynamic>)['family_id'] == familyId,
    );
  }

  @override
  Future<Either<Exception, List<PersonEntity>>> getPeople() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        return Left(Exception('Not signed in.'));
      }
      final response = await getFamilyIdsForUser(userId);

      if (response.isEmpty) {
        return Left(Exception('No families found'));
      }

      final familyId = response.first;
      final people = await getProfilesWithRoleForFamily(familyId);
      return Right(people);
    } on Object catch (e) {
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
    return rows
        .map((e) => (e as Map<String, dynamic>)['family_id'] as String)
        .toList();
  }

  @override
  Future<List<String>> getMyFamilyRole() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      return [];
    }
    final res = await _client
        .from('family_memberships')
        .select('role')
        .eq('user_id', userId);

    final rows = res as List;
    return rows
        .map((e) => (e as Map<String, dynamic>)['role'] as String)
        .toList();
  }

  @override
  Future<List<PersonEntity>> getProfilesWithRoleForFamily(
    String familyId,
  ) async {
    // TODO(diogohenrique): replace this with a edge function

    // Step 1: get memberships (user_id + role) for the family
    final membershipsRes = await _client
        .from('family_memberships')
        .select('user_id, role')
        .eq('family_id', familyId);
    final memberships = (membershipsRes as List).map((e) {
      final entry = e as Map<String, dynamic>;
      return {'user_id': entry['user_id'], 'role': entry['role']};
    }).toList();

    final userIds = memberships.map((m) => m['user_id'] as String).toList();
    if (userIds.isEmpty) return [];

    // Step 2: fetch profiles for those user_ids
    final profilesRes = await _client
        .from('profiles')
        .select()
        .inFilter('id', userIds);

    final profiles = profilesRes as List;

    // Step 3: merge role back into each profile (matches the original SELECT)
    final roleByUserId = {for (final m in memberships) m['user_id']: m['role']};

    return profiles
        .map((p) {
          final person = PersonEntity.from(p);
          final role = roleByUserId[person?.id] as String?;
          return person?.copyWith(role: role);
        })
        .nonNulls
        .toList();
  }

  @override
  Future<Either<Exception, bool>> updateFamilyName({
    required String familyId,
    required String name,
  }) async {
    try {
      await _client.from('families').update({'name': name}).eq('id', familyId);
      return const Right(true);
    } on Object catch (e) {
      debugPrint('Error updating family name: $e');
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, bool>> removeMember({
    required String familyId,
    required String userId,
  }) async {
    try {
      // Data impact: removing a user (admin-remove or self-leave) also
      // deletes the notes and reminders they created in this family. These
      // run before the membership delete while RLS still sees the caller
      // as a family member.
      //
      // Cleanup scope under the current policies:
      // - notes DELETE is membership-scoped
      //   (sqls/notes_schema.sql:83-92 "notes_delete_member"): any member
      //   can delete any note in the family, so an admin removing someone
      //   else cleans up that member's notes.
      // - reminders DELETE is creator-scoped
      //   (sqls/database_schema.sql:242 "Enable delete for users based on
      //   user_id"): only the creator's rows match, so an admin removing
      //   someone else leaves that member's reminders behind while the
      //   membership removal still proceeds. Self-leave (the common path)
      //   cleans up its own rows.
      //
      // A transactional delete (edge function with elevated server
      // privileges, see issue #39) would make this atomic; until then
      // cleanup failures are logged with family/user context below and do
      // not block the membership removal.
      //
      // Backend enforcement: families update/delete is admin/owner-only
      // and family_memberships delete is self-or-admin-only in Supabase
      // RLS (supabase/migrations/20261007120000_family_admin_rls.sql);
      // the cubit admin guard is UX/defense-in-depth only and must not be
      // relied on as the security boundary.
      try {
        await _client
            .from('notes')
            .delete()
            .eq('family_id', familyId)
            .eq('created_by', userId);
      } on Object catch (e) {
        debugPrint(
          'Error deleting notes for user $userId in family $familyId: $e',
        );
      }
      try {
        await _client
            .from('reminders')
            .delete()
            .eq('family_id', familyId)
            .eq('created_by', userId);
      } on Object catch (e) {
        debugPrint(
          'Error deleting reminders for user $userId in family $familyId: $e',
        );
      }
      await _client
          .from('family_memberships')
          .delete()
          .eq('family_id', familyId)
          .eq('user_id', userId);
      return const Right(true);
    } on Object catch (e) {
      debugPrint('Error removing member: $e');
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, bool>> deleteFamily({
    required String familyId,
  }) async {
    try {
      // Delete family memberships first (foreign key constraint)
      await _client
          .from('family_memberships')
          .delete()
          .eq('family_id', familyId);

      // Delete people records
      await _client.from('people').delete().eq('family_id', familyId);

      // Delete the family
      await _client.from('families').delete().eq('id', familyId);

      return const Right(true);
    } on Object catch (e) {
      debugPrint('Error deleting family: $e');
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, String?>> getMyFamilyId() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        return Left(Exception('Not signed in.'));
      }
      final response = await _client
          .from('family_memberships')
          .select('family_id')
          .eq('user_id', userId)
          .limit(1);

      if (response.isEmpty) {
        return const Right(null);
      }

      final familyId = response.first['family_id'] as String;
      return Right(familyId);
    } on Object catch (e) {
      debugPrint('Error getting family ID: $e');
      return Left(Exception(e.toString()));
    }
  }
}
