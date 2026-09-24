import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/auth/auth_state_notifier.dart';
import 'package:house_mira/core/functions/edget_functions.dart';
import 'package:house_mira/core/injections/service_locator.dart';
import 'package:house_mira/core/router/app_routes.dart';
import 'package:house_mira/core/router/main_shell.dart';
import 'package:house_mira/core/router/splash_view.dart';
import 'package:house_mira/core/router/tab_refresh_coordinator.dart';
import 'package:house_mira/features/account/application/notification_permission_service.dart';
import 'package:house_mira/features/account/presentation/cubit/account_cubit.dart';
import 'package:house_mira/features/account/presentation/cubit/account_state.dart';
import 'package:house_mira/features/account/presentation/cubit/manage_profile_cubit.dart';
import 'package:house_mira/features/account/presentation/cubit/notification_settings_cubit.dart';
import 'package:house_mira/features/account/presentation/views/account_view.dart';
import 'package:house_mira/features/account/presentation/views/manage_profile_screen.dart';
import 'package:house_mira/features/account/presentation/views/notification_settings_screen.dart';
import 'package:house_mira/features/home/presentation/cubit/home_cubit.dart';
import 'package:house_mira/features/home/presentation/views/home_view.dart';
import 'package:house_mira/features/login/presentation/cubit/sign_up_cubit.dart';
import 'package:house_mira/features/login/presentation/views/sign_up_screen.dart';
import 'package:house_mira/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:house_mira/features/people/presentation/cubit/family_settings_cubit.dart';
import 'package:house_mira/features/people/presentation/cubit/invite_people_cubit.dart';
import 'package:house_mira/features/people/presentation/cubit/people_cubit.dart';
import 'package:house_mira/features/people/presentation/views/family_settings_screen.dart';
import 'package:house_mira/features/people/presentation/views/invite_people_screen.dart';
import 'package:house_mira/features/people/presentation/views/people_view.dart';
import 'package:house_mira/features/reminders/presentation/cubit/create_reminder_cubit.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:house_mira/features/reminders/presentation/screens/create_reminder_screen.dart';
import 'package:house_mira/features/reminders/presentation/screens/reminders_view.dart';

/// Builds the application router.
///
/// When [authStateNotifier] is provided, the router stays synchronized with
/// Supabase `onAuthStateChange` events: every sign-in, sign-out, token
/// refresh, or session recovery triggers a redirect re-evaluation via
/// `refreshListenable`. While the initial session recovery is still in
/// flight ([AuthStateNotifier.isInitialized] == false), navigation is held
/// on the splash screen so no unauthenticated content flashes on restart.
/// The pre-auth location (tab or deep link) is preserved in the splash
/// `next` query parameter and restored afterwards.
///
/// Guest usage is allowed: unauthenticated users can browse the main tabs
/// (each view renders its own signed-out empty state). The enforced rules
/// are exactly the [resolveAppRedirect] matrix: splash gate, signed-in away
/// from sign-up, and invalid invite codes falling back to people.
///
/// Deep links: `/invite/<code>` (App Link `https://vitafolder.app/invite/…`)
/// lands on the people tab with the code pre-filled for one-tap joining.
/// Notification taps are payload-routed by `MyApp` via
/// [notificationLocationFor].
///
/// Cold-start laziness: no cubit is constructed by [createRouter] itself.
/// Each `StatefulShellBranch` provides its tab cubit through a
/// `*CubitFactory` (default: the GetIt lazy singleton), and each one-shot
/// screen route (`/sign-up`, `/invite-people`, `/manage-profile`,
/// `/notification-settings`, `/family-settings`, `/create-reminder`)
/// provides its own cubit the same way. go_router builds only the active
/// branch, so a cold start resolves just the visited route's factory (e.g.
/// `/home` constructs only the home cubit; the people/reminders/account
/// singletons and all one-shot graphs stay unbuilt until first visited —
/// pinned by the 'route-scoped cubit laziness' router test). `AuthService`
/// stays global (provided above the router in `main.dart`) because every
/// tab reads it for guest gating.
///
/// Factory contract:
/// * Tab factories (`home`, `people`, `reminders`, `account`) are **shared**.
///   They must return the same lazy-singleton instance on every call and the
///   provider uses `BlocProvider.value` (never closes). Tests must return a
///   single shared instance and close it manually in `addTearDown`.
/// * One-shot factories (`signUp`, `invitePeople`, `createReminder`,
///   `familySettings`, `notificationSettings`, `manageProfile`) are **fresh**.
///   They must build a new cubit on every call; the route owns it via
///   `BlocProvider(create:)` (auto-closed on pop). Tests must return a new
///   instance per call and never close it manually — returning the same
///   instance to `create:` is a use-after-close footgun.
///
/// Cross-tab refresh never pulls sibling cubits from views. Tab builders
/// register refresh closures on [refreshCoordinator] when they actually
/// build; until a tab has been visited its callback stays `null`, so
/// logout/login/save/resync leave unbuilt tabs unbuilt. Views receive plain
/// callbacks (`AccountView.onAuthChanged`, `CreateReminderScreen.onSaved`,
/// `ManageProfileScreen.onProfileSaved`) wired here, so presentation never
/// imports GetIt.
GoRouter createRouter({
  required bool onboardingCompleted,
  AuthStateNotifier? authStateNotifier,
  List<NavigatorObserver>? observers,
  String? initialLocation,
  TabRefreshCoordinator? refreshCoordinator,
  HomeCubit Function()? homeCubitFactory,
  PeopleCubit Function()? peopleCubitFactory,
  RemindersCubit Function()? remindersCubitFactory,
  AccountCubit Function()? accountCubitFactory,
  CreateReminderCubit Function()? createReminderCubitFactory,
  SignUpCubit Function()? signUpCubitFactory,
  InvitePeopleCubit Function()? invitePeopleCubitFactory,
  FamilySettingsCubit Function()? familySettingsCubitFactory,
  NotificationSettingsCubit Function()? notificationSettingsCubitFactory,
  ManageProfileCubit Function()? manageProfileCubitFactory,
}) {
  final notifier = authStateNotifier;
  final coordinator = refreshCoordinator ?? TabRefreshCoordinator();
  final resolveHomeCubit = homeCubitFactory ?? _defaultHomeCubitFactory;
  final resolvePeopleCubit = peopleCubitFactory ?? _defaultPeopleCubitFactory;
  final resolveRemindersCubit =
      remindersCubitFactory ?? _defaultRemindersCubitFactory;
  final resolveAccountCubit =
      accountCubitFactory ?? _defaultAccountCubitFactory;
  final resolveCreateReminderCubit =
      createReminderCubitFactory ?? _defaultCreateReminderCubitFactory;
  final resolveSignUpCubit = signUpCubitFactory ?? _defaultSignUpCubitFactory;
  final resolveInvitePeopleCubit =
      invitePeopleCubitFactory ?? _defaultInvitePeopleCubitFactory;
  final resolveFamilySettingsCubit =
      familySettingsCubitFactory ?? _defaultFamilySettingsCubitFactory;
  final resolveNotificationSettingsCubit =
      notificationSettingsCubitFactory ??
      _defaultNotificationSettingsCubitFactory;
  final resolveManageProfileCubit =
      manageProfileCubitFactory ?? _defaultManageProfileCubitFactory;
  return GoRouter(
    initialLocation:
        initialLocation ??
        _defaultInitialLocation(onboardingCompleted, notifier),
    refreshListenable: notifier,
    redirect: (context, state) {
      if (notifier == null) {
        return null;
      }
      return resolveAppRedirect(
        uri: state.uri,
        isInitialized: notifier.isInitialized,
        isAuthenticated: notifier.isAuthenticated,
        onboardingCompleted: onboardingCompleted,
      );
    },
    observers: observers ?? [],
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashView(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => BlocProvider<SignUpCubit>(
          create: (_) => resolveSignUpCubit(),
          child: const SignUpView(),
        ),
      ),
      GoRoute(
        path: AppRoutes.invitePeople,
        builder: (context, state) {
          final route = InvitePeopleRoute.fromState(state);
          return BlocProvider<InvitePeopleCubit>(
            create: (_) => resolveInvitePeopleCubit(),
            child: InvitePeopleScreen(
              familyName: route.familyName,
              inviteCode: route.inviteCode,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.manageProfile,
        builder: (context, state) => BlocProvider<ManageProfileCubit>(
          create: (_) => resolveManageProfileCubit(),
          child: ManageProfileScreen(
            initialName: coordinator.readAccountName?.call(),
            onProfileSaved: coordinator.refreshAccount,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        builder: (context, state) => BlocProvider<NotificationSettingsCubit>(
          create: (_) => resolveNotificationSettingsCubit(),
          child: const NotificationSettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.familySettings,
        builder: (context, state) => BlocProvider<FamilySettingsCubit>(
          create: (_) => resolveFamilySettingsCubit(),
          child: const FamilySettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.createReminder,
        builder: (context, state) {
          final route = CreateReminderRoute.fromState(state);
          return BlocProvider<CreateReminderCubit>(
            create: (_) => resolveCreateReminderCubit(),
            child: CreateReminderScreen(
              reminder: route.reminder,
              initialType: route.initialType,
              onSaved: coordinator.refreshAfterReminderSave,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '${AppRoutes.inviteJoinBase}/:code',
        builder: (context, state) {
          final route = JoinInviteRoute.fromUri(state.uri);
          // Invalid codes are redirected to people by the redirect matrix;
          // this fallback only covers the single frame before it runs.
          // The Scaffold supplies the Material ancestor the shell
          // otherwise provides on the tab routes.
          // Shares the people singleton intentionally: this top-level route
          // replaces the shell via `go` (never stacked on the people tab),
          // so only one subtree is ever alive at a time.
          return BlocProvider<PeopleCubit>.value(
            value: resolvePeopleCubit(),
            child: Scaffold(body: PeopleView(pendingInviteCode: route?.code)),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.inviteJoinBase,
        builder: (context, state) {
          final route = JoinInviteRoute.fromUri(state.uri);
          // Same shared-singleton note as the `:code` variant above.
          return BlocProvider<PeopleCubit>.value(
            value: resolvePeopleCubit(),
            child: Scaffold(body: PeopleView(pendingInviteCode: route?.code)),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) {
                  final cubit = resolveHomeCubit();
                  coordinator.refreshHome = () =>
                      unawaited(cubit.getHomeData(isRefresh: true));
                  return BlocProvider<HomeCubit>.value(
                    value: cubit,
                    child: const HomeView(),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.people,
                builder: (context, state) {
                  final cubit = resolvePeopleCubit();
                  coordinator.refreshPeople = () =>
                      unawaited(cubit.getPeople(isRefresh: true));
                  return BlocProvider<PeopleCubit>.value(
                    value: cubit,
                    child: PeopleView(
                      pendingInviteCode:
                          state.uri.queryParameters[AppRoutes.inviteCodeParam],
                    ),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reminders,
                builder: (context, state) {
                  final cubit = resolveRemindersCubit();
                  coordinator.refreshReminders = () =>
                      unawaited(cubit.getReminders(type: cubit.selectedType));
                  coordinator.resyncReminderNotifications = () =>
                      cubit.resyncNotifications();
                  return BlocProvider<RemindersCubit>.value(
                    value: cubit,
                    child: const RemindersView(),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.account,
                builder: (context, state) {
                  final cubit = resolveAccountCubit();
                  coordinator.refreshAccount = () =>
                      unawaited(cubit.loadAccount());
                  coordinator.readAccountName = () {
                    final current = cubit.state;
                    return current is AccountLoaded ? current.userName : null;
                  };
                  return BlocProvider<AccountCubit>.value(
                    value: cubit,
                    child: AccountView(onAuthChanged: coordinator.refreshAll),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

HomeCubit _defaultHomeCubitFactory() =>
    slInstance<HomeCubit>(instanceName: 'homeCubit');

PeopleCubit _defaultPeopleCubitFactory() =>
    slInstance<PeopleCubit>(instanceName: 'peopleCubit');

RemindersCubit _defaultRemindersCubitFactory() =>
    slInstance<RemindersCubit>(instanceName: 'remindersCubit');

AccountCubit _defaultAccountCubitFactory() =>
    slInstance<AccountCubit>(instanceName: 'accountCubit');

/// One-shot editor: each visit gets a fresh cubit owned by
/// `BlocProvider(create:)` (auto-closed on pop), so a prior `Success`/`Error`
/// never leaks into the next visit.
CreateReminderCubit _defaultCreateReminderCubitFactory() => CreateReminderCubit(
  createReminderUsecase: slInstance(instanceName: 'createReminderUsecase'),
  updateReminderUsecase: slInstance(instanceName: 'updateReminderUsecase'),
  authService: slInstance<AuthService>(instanceName: 'authService'),
  peopleRepository: slInstance(instanceName: 'peopleRepositoryImpl'),
  notificationService: slInstance(instanceName: 'reminderNotificationService'),
);

/// Sign-up is a one-shot form with no shared tab state: each visit gets a
/// fresh cubit built from the global [AuthService].
SignUpCubit _defaultSignUpCubitFactory() =>
    SignUpCubit(slInstance<AuthService>(instanceName: 'authService'));

/// Invites are one-shot sends: each visit gets a fresh cubit built from
/// the global [EdgetFunctions] client.
InvitePeopleCubit _defaultInvitePeopleCubitFactory() => InvitePeopleCubit(
  edgetFunctions: slInstance<EdgetFunctions>(instanceName: 'edgetFunctions'),
);

/// One-shot settings form: fresh per visit, owned by `BlocProvider(create:)`.
FamilySettingsCubit _defaultFamilySettingsCubitFactory() => FamilySettingsCubit(
  getPeopleUsecase: slInstance(instanceName: 'getPeopleUsecase'),
  getMyFamilyIdUsecase: slInstance(instanceName: 'getMyFamilyIdUsecase'),
  updateFamilyNameUsecase: slInstance(instanceName: 'updateFamilyNameUsecase'),
  removeMemberUsecase: slInstance(instanceName: 'removeMemberUsecase'),
  deleteFamilyUsecase: slInstance(instanceName: 'deleteFamilyUsecase'),
  authService: slInstance<AuthService>(instanceName: 'authService'),
);

/// One-shot settings form: fresh per visit, owned by `BlocProvider(create:)`.
NotificationSettingsCubit _defaultNotificationSettingsCubitFactory() =>
    NotificationSettingsCubit(
      permissionService: NotificationPermissionService(),
      storage: slInstance(instanceName: 'localStorageDatasource'),
      notificationService: slInstance(
        instanceName: 'reminderNotificationService',
      ),
    );

/// One-shot form: fresh per visit, owned by `BlocProvider(create:)`.
ManageProfileCubit _defaultManageProfileCubitFactory() => ManageProfileCubit(
  authService: slInstance<AuthService>(instanceName: 'authService'),
);

/// Default cold-start location: hold on splash (preserving the post-auth
/// landing in `next`) while session recovery is in flight, else go straight
/// to home or onboarding.
String _defaultInitialLocation(
  bool onboardingCompleted,
  AuthStateNotifier? notifier,
) {
  final landing = onboardingCompleted ? AppRoutes.home : AppRoutes.onboarding;
  if (notifier != null && !notifier.isInitialized) {
    final encoded = Uri.encodeComponent(landing);
    return '${AppRoutes.splash}?${AppRoutes.nextParam}=$encoded';
  }
  return landing;
}
