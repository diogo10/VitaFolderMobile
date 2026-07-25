import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_cubit.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_state.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/family_entity.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/person_entity.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';

class FakeAuthService extends AuthService {
  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  User? get currentUser => null;
}

class FakePeopleRepository implements PeopleRepository {
  @override
  Future<Either<Exception, List<PersonEntity>>> getPeople() async => Right([]);

  @override
  Future<Either<Exception, FamilyEntity>> getFamily() async => Right(
        FamilyEntity(name: 'Test', inviteCode: 'ABC123'),
      );

  @override
  Future<Either<Exception, bool>> createFamily({required String name, required String inviteCode}) async => Right(true);
}

void main() {
  group('AccountCubit', () {
    test('signIn emits AccountLoaded with valid credentials', () async {
      final cubit = AccountCubit(
        authService: FakeAuthService(),
        peopleRepository: FakePeopleRepository(),
      );

      await cubit.signIn('user@example.com', 'password123');

      expect(cubit.state, isA<AccountLoaded>());
    });
  });
}
