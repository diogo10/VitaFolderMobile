import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/auth/google_sign_in_handler.dart';
import 'package:house_mira/core/widgets/sand/google_g_icon.dart';
import 'package:house_mira/features/account/presentation/cubit/account_cubit.dart';
import 'package:house_mira/features/account/presentation/views/no_account_view.dart';
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

  Completer<PersonEntity?> personCompleter = Completer<PersonEntity?>()
    ..complete(null);
  String? lastSignInEmail;
  String? lastSignInPassword;
  String? lastResetEmail;

  @override
  Future<PersonEntity?> getAsPersonEntity() => personCompleter.future;

  @override
  Future<void> signIn({required String email, required String password}) async {
    lastSignInEmail = email;
    lastSignInPassword = password;
  }

  @override
  Future<void> resetPassword(String email) async {
    lastResetEmail = email;
  }

  @override
  User? get currentUser => null;
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
  late _FakeAuthService authService;
  late _FakePeopleRepository peopleRepository;

  setUp(() {
    authService = _FakeAuthService();
    peopleRepository = _FakePeopleRepository();
  });

  Future<void> pumpNoAccount(WidgetTester tester, AccountCubit cubit) async {
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AccountCubit>.value(
          value: cubit,
          child: const NoAccountView(),
        ),
      ),
    );
    await tester.pump();
  }

  AccountCubit buildCubit() => AccountCubit(
    authService: authService,
    peopleRepository: peopleRepository,
  );

  group('NoAccountView', () {
    testWidgets('renders hero, auth and trust content', (tester) async {
      await pumpNoAccount(tester, buildCubit());

      expect(find.text('HouseMira'), findsOneWidget);
      expect(
        find.textContaining('Your family,', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('organised together', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text(
          'Manage your circle, set reminders and collaborate as a family — all in one place.',
        ),
        findsOneWidget,
      );
      expect(find.text('Chores'), findsOneWidget);
      expect(find.text('Appointments'), findsOneWidget);
      expect(find.text('Family Circle'), findsOneWidget);

      expect(find.byType(GoogleGIcon), findsOneWidget);
      expect(find.byIcon(Icons.apple), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('or sign in with email'), findsOneWidget);

      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(
        find.textContaining('Create a free account', findRichText: true),
        findsOneWidget,
      );

      expect(find.text('Secure & private'), findsOneWidget);
      expect(find.text('Free to start'), findsOneWidget);
      expect(find.text('Family plan'), findsOneWidget);
    });

    testWidgets('signs in with entered credentials', (tester) async {
      await pumpNoAccount(tester, buildCubit());

      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'secret');
      await tester.ensureVisible(find.text('Sign In'));
      await tester.pump();
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(authService.lastSignInEmail, 'user@example.com');
      expect(authService.lastSignInPassword, 'secret');
    });

    testWidgets('requests password reset with entered email', (tester) async {
      await pumpNoAccount(tester, buildCubit());

      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.ensureVisible(find.text('Forgot password?'));
      await tester.pump();
      await tester.tap(find.text('Forgot password?'));
      await tester.pump();

      expect(authService.lastResetEmail, 'user@example.com');
    });

    testWidgets('toggles password visibility', (tester) async {
      await pumpNoAccount(tester, buildCubit());

      expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
      await tester.ensureVisible(find.byIcon(Icons.visibility_rounded));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.visibility_rounded));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);
    });

    testWidgets('shows loading spinner while account is loading', (
      tester,
    ) async {
      // Pending lookup keeps the cubit in AccountLoading while pumping.
      authService.personCompleter = Completer<PersonEntity?>();
      final cubit = buildCubit();
      unawaited(cubit.loadAccount());

      await pumpNoAccount(tester, cubit);

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      authService.personCompleter.complete(null);
      await tester.pump();
    });
  });
}
