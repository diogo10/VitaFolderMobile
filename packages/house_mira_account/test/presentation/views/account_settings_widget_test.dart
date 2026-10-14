import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira_core/auth/auth_service.dart';
import 'package:house_mira_core/auth/google_sign_in_handler.dart';
import 'package:house_mira_account/presentation/cubit/account_cubit.dart';
import 'package:house_mira_account/presentation/cubit/account_state.dart';
import 'package:house_mira_account/presentation/views/account_settings_widget.dart';
import 'package:house_mira_core/router/app_routes.dart';
import 'package:house_mira_people/domain/entities/family_entity.dart';
import 'package:house_mira_people/domain/entities/person_entity.dart';
import 'package:house_mira_people/domain/repository/people_repository.dart';
import 'package:house_mira_core/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:house_mira_core/subscriptions/subscription_service.dart';

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
  Future<void> pumpSettings(
    WidgetTester tester,
    AccountCubit cubit, {
    String familyCode = 'ABC123',
  }) async {
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AccountCubit>.value(
          value: cubit,
          // Mirrors production: AccountLoadedWidget hosts the settings
          // column inside a SingleChildScrollView.
          child: Scaffold(
            body: SingleChildScrollView(
              child: AccountSettingsWidget(familyCode: familyCode),
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
    subscriptionService: SubscriptionService(),
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

    testWidgets('hides the family section when there is no family', (
      tester,
    ) async {
      final auth = _FakeAuthService();
      await pumpSettings(tester, buildCubit(auth), familyCode: '');

      expect(find.text('Delete Account'), findsOneWidget);
      expect(find.text('Invite Members'), findsNothing);
      expect(find.text('Family Settings'), findsNothing);
    });

    testWidgets('shows family settings to every family member', (tester) async {
      final auth = _FakeAuthService();
      await pumpSettings(tester, buildCubit(auth));

      expect(find.text('Family Settings'), findsOneWidget);
      expect(find.text('Invite Members'), findsOneWidget);
    });
  });

  group('AccountSettingsWidget support item', () {
    testWidgets('renders the Support menu item', (tester) async {
      final auth = _FakeAuthService();
      await pumpSettings(tester, buildCubit(auth));

      final l = AppLocalizations.of(
        tester.element(find.byType(AccountSettingsWidget)),
      )!;
      expect(find.text(l.accountSettingsSupport), findsOneWidget);
    });

    testWidgets('shows Support even without a family', (tester) async {
      final auth = _FakeAuthService();
      await pumpSettings(tester, buildCubit(auth), familyCode: '');

      final l = AppLocalizations.of(
        tester.element(find.byType(AccountSettingsWidget)),
      )!;
      expect(find.text(l.accountSettingsSupport), findsOneWidget);
    });

    testWidgets('tapping Support navigates to the support route', (
      tester,
    ) async {
      final auth = _FakeAuthService();
      final cubit = buildCubit(auth);
      addTearDown(cubit.close);
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (_, _) => BlocProvider<AccountCubit>.value(
              value: cubit,
              child: const Scaffold(
                body: SingleChildScrollView(
                  child: AccountSettingsWidget(familyCode: 'ABC123'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.support,
            builder: (_, _) => const Scaffold(body: Text('support-stub')),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pump();

      final l = AppLocalizations.of(
        tester.element(find.byType(AccountSettingsWidget)),
      )!;
      await tester.ensureVisible(find.text(l.accountSettingsSupport));
      await tester.tap(find.text(l.accountSettingsSupport));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(router.state.uri.path, AppRoutes.support);
      expect(find.text('support-stub'), findsOneWidget);
    });
  });

  group('AccountSettingsWidget privacy policy', () {
    testWidgets('renders under the policy options section', (tester) async {
      final auth = _FakeAuthService();
      await pumpSettings(tester, buildCubit(auth));

      final l = AppLocalizations.of(
        tester.element(find.byType(AccountSettingsWidget)),
      )!;
      expect(find.text(l.accountSettingsPolicySection), findsOneWidget);
      expect(find.text(l.accountSettingsPrivacyPolicy), findsOneWidget);
    });

    testWidgets('tapping Privacy Policy navigates to the privacy route', (
      tester,
    ) async {
      final auth = _FakeAuthService();
      final cubit = buildCubit(auth);
      addTearDown(cubit.close);
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (_, _) => BlocProvider<AccountCubit>.value(
              value: cubit,
              child: const Scaffold(
                body: SingleChildScrollView(
                  child: AccountSettingsWidget(familyCode: 'ABC123'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.privacy,
            builder: (_, _) => const Scaffold(body: Text('privacy-stub')),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pump();

      final l = AppLocalizations.of(
        tester.element(find.byType(AccountSettingsWidget)),
      )!;
      await tester.ensureVisible(find.text(l.accountSettingsPrivacyPolicy));
      await tester.tap(find.text(l.accountSettingsPrivacyPolicy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(router.state.uri.path, AppRoutes.privacy);
      expect(find.text('privacy-stub'), findsOneWidget);
    });
  });
}
