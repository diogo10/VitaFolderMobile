import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/auth/google_sign_in_handler.dart';
import 'package:house_mira/features/account/presentation/cubit/account_cubit.dart';
import 'package:house_mira/features/account/presentation/cubit/account_state.dart';
import 'package:house_mira/features/account/presentation/views/account_settings_widget.dart';
import 'package:house_mira/features/people/domain/entities/family_entity.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:house_mira/generated/app_localizations.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoogleSignInHandler extends Mock implements IGoogleSignInHandler {}

class _FakeAuthService extends AuthService {
  _FakeAuthService()
    : super(
        supabaseClient: _MockSupabaseClient(),
        googleSignInHandler: _MockGoogleSignInHandler(),
      );

  int deleteCalls = 0;

  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
  }

  @override
  Future<void> signOut() async {}
}

class _FakePeopleRepository implements PeopleRepository {
  @override
  Future<Either<Exception, List<PersonEntity>>> getPeople() async => Right([]);

  @override
  Future<Either<Exception, bool>> createFamily({
    required String name,
    required String inviteCode,
  }) async => Right(true);

  @override
  Future<Either<Exception, FamilyEntity>> getMyFamily() async =>
      Right(FamilyEntity(name: 'Test', inviteCode: 'ABC123'));

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
  Future<List<String>> getMyFamilyRole() async => ['member'];

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

void main() {
  Future<void> pumpSettings(
    WidgetTester tester,
    AccountCubit cubit,
  ) async {
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AccountCubit>.value(
          value: cubit,
          // Mirrors production: AccountLoadedWidget hosts the settings
          // column inside a SingleChildScrollView.
          child: const Scaffold(
            body: SingleChildScrollView(
              child: AccountSettingsWidget(
                familyCode: 'ABC123',
                isAdmin: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  AccountCubit buildCubit(_FakeAuthService auth) => AccountCubit(
    authService: auth,
    peopleRepository: _FakePeopleRepository(),
  );

  group('AccountSettingsWidget delete account', () {
    testWidgets('renders the danger zone delete item', (tester) async {
      final auth = _FakeAuthService();
      await pumpSettings(tester, buildCubit(auth));

      expect(find.text('DANGER ZONE'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('confirming the dialog deletes the account', (tester) async {
      final auth = _FakeAuthService();
      final cubit = buildCubit(auth);
      await pumpSettings(tester, cubit);

      await tester.ensureVisible(find.text('Delete Account'));
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();
      expect(find.text('Delete account?'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(auth.deleteCalls, 1);
      expect(cubit.state, isA<AccountDeletedSuccess>());
    });

    testWidgets('cancelling the dialog keeps the account', (tester) async {
      final auth = _FakeAuthService();
      final cubit = buildCubit(auth);
      await pumpSettings(tester, cubit);

      await tester.ensureVisible(find.text('Delete Account'));
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(auth.deleteCalls, 0);
      expect(find.text('Delete Account'), findsOneWidget);
    });
  });
}
