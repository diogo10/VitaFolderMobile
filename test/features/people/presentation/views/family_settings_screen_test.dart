import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/people/presentation/cubit/family_settings_cubit.dart';
import 'package:house_mira/features/people/presentation/cubit/family_settings_state.dart';
import 'package:house_mira/features/people/presentation/views/family_settings_screen.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockFamilySettingsCubit extends MockCubit<FamilySettingsState>
    implements FamilySettingsCubit {}

void main() {
  late _MockFamilySettingsCubit cubit;

  FamilySettingsLoaded loaded({bool isAdmin = true}) => FamilySettingsLoaded(
    familyName: 'Fam',
    members: const [
      PersonEntity(id: 'u1', name: 'Ana', role: 'admin'),
      PersonEntity(id: 'u2', name: 'Bob', role: 'member'),
    ],
    currentUserId: 'u1',
    isAdmin: isAdmin,
  );

  Future<void> pumpScreen(
    WidgetTester tester, {
    void Function()? onFamilyLeft,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<FamilySettingsCubit>.value(
          value: cubit,
          child: Scaffold(
            body: FamilySettingsScreen(onFamilyLeft: onFamilyLeft),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  setUp(() {
    cubit = _MockFamilySettingsCubit();
    when(() => cubit.loadSettings()).thenAnswer((_) async {});
    when(() => cubit.leaveFamily()).thenAnswer((_) async {});
    when(() => cubit.deleteFamily()).thenAnswer((_) async {});
    when(() => cubit.queueFamilyNameChange(any())).thenReturn(null);
    when(() => cubit.queueMemberRemoval(any())).thenReturn(null);
    when(() => cubit.saveChanges()).thenAnswer((_) async {});
  });

  group('FamilySettingsScreen leave family', () {
    testWidgets('shows leave button for admins alongside delete', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(loaded());
      await pumpScreen(tester);
      final l = AppLocalizations.of(
        tester.element(find.byType(FamilySettingsScreen)),
      )!;

      expect(find.text(l.leaveFamilyButton), findsOneWidget);
      expect(find.text(l.deleteFamilyButton), findsOneWidget);
    });

    testWidgets('shows leave button but no delete for non-admins', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(loaded(isAdmin: false));
      await pumpScreen(tester);
      final l = AppLocalizations.of(
        tester.element(find.byType(FamilySettingsScreen)),
      )!;

      expect(find.text(l.leaveFamilyButton), findsOneWidget);
      expect(find.text(l.deleteFamilyButton), findsNothing);
    });

    testWidgets('cancelling the dialog takes no action', (tester) async {
      when(() => cubit.state).thenReturn(loaded());
      await pumpScreen(tester);
      final l = AppLocalizations.of(
        tester.element(find.byType(FamilySettingsScreen)),
      )!;

      await tester.ensureVisible(find.text(l.leaveFamilyButton));
      await tester.tap(find.text(l.leaveFamilyButton));
      await tester.pumpAndSettle();
      expect(find.text(l.leaveFamilyConfirmTitle), findsOneWidget);

      await tester.tap(find.text(l.cancel));
      await tester.pumpAndSettle();

      verifyNever(() => cubit.leaveFamily());
      expect(find.text(l.leaveFamilyConfirmTitle), findsNothing);
    });

    testWidgets('confirming the dialog leaves the family', (tester) async {
      when(() => cubit.state).thenReturn(loaded());
      await pumpScreen(tester);
      final l = AppLocalizations.of(
        tester.element(find.byType(FamilySettingsScreen)),
      )!;

      await tester.ensureVisible(find.text(l.leaveFamilyButton));
      await tester.tap(find.text(l.leaveFamilyButton));
      await tester.pumpAndSettle();

      // Dialog confirm button shares its label with the section button;
      // the dialog one is rendered last.
      await tester.tap(find.text(l.leaveFamilyButton).last);
      await tester.pumpAndSettle();

      verify(() => cubit.leaveFamily()).called(1);
    });
  });

  group('FamilySettingsScreen remove member', () {
    testWidgets('shows remove icon for admins', (tester) async {
      when(() => cubit.state).thenReturn(loaded());
      await pumpScreen(tester);

      expect(find.byIcon(Icons.person_remove_rounded), findsOneWidget);
    });

    testWidgets('hides remove icon for non-admins', (tester) async {
      when(() => cubit.state).thenReturn(loaded(isAdmin: false));
      await pumpScreen(tester);

      expect(find.byIcon(Icons.person_remove_rounded), findsNothing);
    });

    testWidgets('remove dialog uses the dedicated remove label', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(loaded());
      await pumpScreen(tester);
      final l = AppLocalizations.of(
        tester.element(find.byType(FamilySettingsScreen)),
      )!;

      await tester.tap(find.byIcon(Icons.person_remove_rounded));
      await tester.pumpAndSettle();

      expect(find.text(l.removeMemberConfirm('Bob', 'Fam')), findsOneWidget);
      expect(find.text(l.removeMemberConfirmButton), findsOneWidget);
      expect(find.text(l.deleteFamilyButton), findsOneWidget);
    });

    testWidgets('confirming the remove dialog queues the removal', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(loaded());
      await pumpScreen(tester);
      final l = AppLocalizations.of(
        tester.element(find.byType(FamilySettingsScreen)),
      )!;

      await tester.tap(find.byIcon(Icons.person_remove_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l.removeMemberConfirmButton));
      await tester.pumpAndSettle();

      verify(() => cubit.queueMemberRemoval('u2')).called(1);
    });
  });

  group('FamilySettingsScreen leave success refresh', () {
    testWidgets('leave success refreshes account and navigates to it', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(loaded());
      whenListen(
        cubit,
        Stream<FamilySettingsState>.fromIterable([
          loaded(),
          const FamilySettingsLeaveSuccess(),
        ]),
        initialState: loaded(),
      );
      var refreshed = false;
      final router = GoRouter(
        initialLocation: '/family-settings',
        routes: [
          GoRoute(
            path: '/family-settings',
            builder: (context, state) =>
                BlocProvider<FamilySettingsCubit>.value(
                  value: cubit,
                  child: Scaffold(
                    body: FamilySettingsScreen(
                      onFamilyLeft: () => refreshed = true,
                    ),
                  ),
                ),
          ),
          GoRoute(
            path: '/account',
            builder: (context, state) => const Scaffold(body: Text('account')),
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
      await tester.pumpAndSettle();

      expect(refreshed, isTrue);
      expect(router.state.uri.path, '/account');
      expect(find.text('account'), findsOneWidget);
    });
  });
}
