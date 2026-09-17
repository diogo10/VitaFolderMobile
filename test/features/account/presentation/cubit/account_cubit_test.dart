import 'package:bloc_test/bloc_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/auth/google_sign_in_handler.dart';
import 'package:house_mira/features/account/presentation/cubit/account_cubit.dart';
import 'package:house_mira/features/account/presentation/cubit/account_state.dart';
import 'package:house_mira/features/people/domain/entities/family_entity.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoogleSignInHandler extends Mock implements IGoogleSignInHandler {}

class _FakeAuthService extends AuthService {
  User? stubUser;
  PersonEntity? stubPerson;
  Object? personError;
  Object? signInError;
  Object? signOutError;
  Object? resetError;
  int signInCalls = 0;

  _FakeAuthService({
    this.stubUser,
    this.stubPerson,
    this.personError,
    this.signInError,
    this.signOutError,
    this.resetError,
    SupabaseClient? supabaseClient,
    IGoogleSignInHandler? googleSignInHandler,
  }) : super(
         supabaseClient: supabaseClient ?? _MockSupabaseClient(),
         googleSignInHandler: googleSignInHandler ?? _MockGoogleSignInHandler(),
       );

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls++;
    if (signInError != null) throw signInError!;
  }

  @override
  User? get currentUser => stubUser;

  @override
  Future<PersonEntity?> getAsPersonEntity() async {
    if (personError != null) throw personError!;
    return stubPerson;
  }

  @override
  Future<void> signOut() async {
    if (signOutError != null) throw signOutError!;
  }

  @override
  Future<void> resetPassword(String email) async {
    if (resetError != null) throw resetError!;
  }
}

class _FakePeopleRepository implements PeopleRepository {
  Either<Exception, FamilyEntity> familyResult = Right(
    FamilyEntity(name: 'Test', inviteCode: 'ABC123'),
  );
  List<String> roles = const ['member'];

  @override
  Future<Either<Exception, List<PersonEntity>>> getPeople() async => Right([]);

  @override
  Future<Either<Exception, bool>> createFamily({
    required String name,
    required String inviteCode,
  }) async => Right(true);

  @override
  Future<Either<Exception, FamilyEntity>> getMyFamily() async => familyResult;

  @override
  Future<Either<Exception, bool>> joinFamily({
    required String inviteCode,
  }) async => Right(true);

  @override
  Future<FamilyEntity?> getFamilyBy(String id) async =>
      FamilyEntity(name: 'Test', inviteCode: 'ABC123');

  @override
  Future<List<String>> getFamilyIdsForUser(String userId) async => [];

  @override
  Future<List<PersonEntity>> getProfilesWithRoleForFamily(
    String familyId,
  ) async => [];

  @override
  Future<List<String>> getMyFamilyRole() async => roles;

  @override
  Future<Either<Exception, bool>> updateFamilyName({
    required String familyId,
    required String name,
  }) async => Right(true);

  @override
  Future<Either<Exception, bool>> removeMember({
    required String familyId,
    required String userId,
  }) async => Right(true);

  @override
  Future<Either<Exception, bool>> deleteFamily({
    required String familyId,
  }) async => Right(true);

  @override
  Future<Either<Exception, String?>> getMyFamilyId() async =>
      Right('fake-family');
}

User _testUser() =>
    User.fromJson({'id': 'user-id', 'email': 'user@example.com'})!;

PersonEntity _testPerson() =>
    PersonEntity(id: 'user-id', name: 'Test User', email: 'user@example.com');

void main() {
  group('AccountCubit', () {
    test('signIn emits AccountLoaded with valid credentials', () async {
      final cubit = AccountCubit(
        authService: _FakeAuthService(
          stubUser: _testUser(),
          stubPerson: _testPerson(),
        ),
        peopleRepository: _FakePeopleRepository(),
      );
      addTearDown(cubit.close);

      await cubit.signIn('user@example.com', 'password123');

      expect(cubit.state, isA<AccountLoaded>());
      final loaded = cubit.state as AccountLoaded;
      expect(loaded.userName, 'Test User');
      expect(loaded.email, 'user@example.com');
      expect(loaded.familyCode, 'ABC123');
      expect(loaded.myRole, 'member');
    });

    test(
      'signIn with blank credentials emits NoAccount without calling API',
      () async {
        final auth = _FakeAuthService(
          stubUser: _testUser(),
          stubPerson: _testPerson(),
        );
        final cubit = AccountCubit(
          authService: auth,
          peopleRepository: _FakePeopleRepository(),
        );
        addTearDown(cubit.close);

        await cubit.signIn('   ', 'password123');

        expect(cubit.state, isA<NoAccount>());
        expect(auth.signInCalls, 0);
      },
    );

    test(
      'signIn emits LoginFailed when no current user after signIn',
      () async {
        final cubit = AccountCubit(
          authService: _FakeAuthService(stubUser: null, stubPerson: null),
          peopleRepository: _FakePeopleRepository(),
        );
        addTearDown(cubit.close);

        await cubit.signIn('user@example.com', 'password123');

        expect(cubit.state, isA<LoginFailed>());
      },
    );

    test('signIn emits LoginFailed on AuthApiException', () async {
      final cubit = AccountCubit(
        authService: _FakeAuthService(
          stubUser: _testUser(),
          stubPerson: _testPerson(),
          signInError: const AuthApiException('bad'),
        ),
        peopleRepository: _FakePeopleRepository(),
      );
      addTearDown(cubit.close);

      await cubit.signIn('user@example.com', 'wrong');

      expect(cubit.state, isA<LoginFailed>());
    });

    blocTest<AccountCubit, AccountState>(
      'loadAccount emits loading then loaded when user exists',
      build: () => AccountCubit(
        authService: _FakeAuthService(
          stubUser: _testUser(),
          stubPerson: _testPerson(),
        ),
        peopleRepository: _FakePeopleRepository(),
      ),
      act: (cubit) => cubit.loadAccount(),
      expect: () => [isA<AccountLoading>(), isA<AccountLoaded>()],
    );

    blocTest<AccountCubit, AccountState>(
      'loadAccount emits loading then NoAccount when user is null',
      build: () => AccountCubit(
        authService: _FakeAuthService(stubUser: null, stubPerson: null),
        peopleRepository: _FakePeopleRepository(),
      ),
      act: (cubit) => cubit.loadAccount(),
      expect: () => [isA<AccountLoading>(), isA<NoAccount>()],
    );

    blocTest<AccountCubit, AccountState>(
      'signOut emits loading then logout success',
      build: () => AccountCubit(
        authService: _FakeAuthService(),
        peopleRepository: _FakePeopleRepository(),
      ),
      act: (cubit) => cubit.signOut(),
      expect: () => [isA<AccountLoading>(), isA<AccountLogoutSuccess>()],
    );

    blocTest<AccountCubit, AccountState>(
      'signOut emits NoAccount when signOut throws',
      build: () => AccountCubit(
        authService: _FakeAuthService(signOutError: Exception('boom')),
        peopleRepository: _FakePeopleRepository(),
      ),
      act: (cubit) => cubit.signOut(),
      expect: () => [isA<AccountLoading>(), isA<NoAccount>()],
    );

    blocTest<AccountCubit, AccountState>(
      'forgotPassword emits PasswordResetSent on success',
      build: () => AccountCubit(
        authService: _FakeAuthService(),
        peopleRepository: _FakePeopleRepository(),
      ),
      act: (cubit) => cubit.forgotPassword('user@example.com'),
      expect: () => [isA<PasswordResetSent>()],
    );

    blocTest<AccountCubit, AccountState>(
      'forgotPassword emits emptyEmail error on blank email',
      build: () => AccountCubit(
        authService: _FakeAuthService(),
        peopleRepository: _FakePeopleRepository(),
      ),
      act: (cubit) => cubit.forgotPassword('   '),
      expect: () => [
        isA<PasswordResetError>().having(
          (e) => e.code,
          'code',
          PasswordResetErrorCode.emptyEmail,
        ),
      ],
    );

    blocTest<AccountCubit, AccountState>(
      'forgotPassword emits sendFailed when reset throws',
      build: () => AccountCubit(
        authService: _FakeAuthService(resetError: Exception('boom')),
        peopleRepository: _FakePeopleRepository(),
      ),
      act: (cubit) => cubit.forgotPassword('user@example.com'),
      expect: () => [
        isA<PasswordResetError>().having(
          (e) => e.code,
          'code',
          PasswordResetErrorCode.sendFailed,
        ),
      ],
    );
    blocTest<AccountCubit, AccountState>(
      'loadAccount emits NoAccount when the profile lookup throws',
      build: () => AccountCubit(
        authService: _FakeAuthService(personError: Exception('boom')),
        peopleRepository: _FakePeopleRepository(),
      ),
      act: (cubit) => cubit.loadAccount(),
      expect: () => [isA<AccountLoading>(), isA<NoAccount>()],
    );

    blocTest<AccountCubit, AccountState>(
      'signIn emits NoAccount on unexpected errors',
      build: () => AccountCubit(
        authService: _FakeAuthService(
          stubUser: _testUser(),
          stubPerson: _testPerson(),
          signInError: Exception('boom'),
        ),
        peopleRepository: _FakePeopleRepository(),
      ),
      act: (cubit) => cubit.signIn('user@example.com', 'password123'),
      expect: () => [isA<NoAccount>()],
    );
  });
}
