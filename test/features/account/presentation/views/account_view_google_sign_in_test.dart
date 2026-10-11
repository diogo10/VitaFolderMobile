import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira_core/auth/auth_service.dart';
import 'package:house_mira_core/auth/google_sign_in_handler.dart';
import 'package:house_mira_account/presentation/cubit/account_cubit.dart';
import 'package:house_mira_account/presentation/views/account_view.dart';
import 'package:house_mira_people/domain/entities/family_entity.dart';
import 'package:house_mira_people/domain/entities/person_entity.dart';
import 'package:house_mira_people/domain/repository/people_repository.dart';
import 'package:house_mira_core/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:house_mira_core/subscriptions/subscription_service.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoogleSignInHandler extends Mock implements IGoogleSignInHandler {}

class _FailingGoogleAuthService extends AuthService {
  _FailingGoogleAuthService()
    : super(
        supabaseClient: _MockSupabaseClient(),
        googleSignInHandler: _MockGoogleSignInHandler(),
      );

  @override
  Future<({String? name, String? email})?> getCurrentProfile() async => null;

  @override
  Future<User?> signInWithGoogle() async {
    throw const AuthException('Google sign-in failed. Please try again.');
  }
}

class _FakePeopleRepository implements PeopleRepository {
  @override
  Future<Either<Exception, List<PersonEntity>>> getPeople() async =>
      const Right([]);

  @override
  Future<Either<Exception, bool>> createFamily({
    required String name,
    required String inviteCode,
  }) async => const Right(true);

  @override
  Future<Either<Exception, FamilyEntity>> getMyFamily() async =>
      Right(FamilyEntity(name: 'Test', inviteCode: 'ABC123'));

  @override
  Future<Either<Exception, bool>> joinFamily({
    required String inviteCode,
  }) async => const Right(true);

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
  Future<List<String>> getMyFamilyRole() async => ['member'];

  @override
  Future<Either<Exception, bool>> updateFamilyName({
    required String familyId,
    required String name,
  }) async => const Right(true);

  @override
  Future<Either<Exception, bool>> removeMember({
    required String familyId,
    required String userId,
  }) async => const Right(true);

  @override
  Future<Either<Exception, bool>> deleteFamily({
    required String familyId,
  }) async => const Right(true);

  @override
  Future<Either<Exception, String?>> getMyFamilyId() async =>
      const Right('fake-family');
}

void main() {
  testWidgets('shows actionable feedback when Google sign-in fails', (
    tester,
  ) async {
    final cubit = AccountCubit(
      authService: _FailingGoogleAuthService(),
      peopleRepository: _FakePeopleRepository(),
      authSignedInStream: const Stream.empty(),
      subscriptionService: SubscriptionService(),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AccountCubit>.value(
          value: cubit,
          child: const AccountView(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await cubit.signInWithGoogle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final l = AppLocalizations.of(tester.element(find.byType(AccountView)))!;
    expect(find.text(l.accountGoogleSignInFailed), findsOneWidget);
  });
}
