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
import 'package:house_mira/features/account/presentation/cubit/account_cubit.dart';
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
GoRouter createRouter({
  required bool onboardingCompleted,
  AuthStateNotifier? authStateNotifier,
  List<NavigatorObserver>? observers,
  String? initialLocation,
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
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider<AccountCubit>.value(value: resolveAccountCubit()),
            BlocProvider<ManageProfileCubit>.value(
              value: resolveManageProfileCubit(),
            ),
          ],
          child: const ManageProfileScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        builder: (context, state) =>
            BlocProvider<NotificationSettingsCubit>.value(
              value: resolveNotificationSettingsCubit(),
              child: const NotificationSettingsScreen(),
            ),
      ),
      GoRoute(
        path: AppRoutes.familySettings,
        builder: (context, state) => BlocProvider<FamilySettingsCubit>.value(
          value: resolveFamilySettingsCubit(),
          child: const FamilySettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.createReminder,
        builder: (context, state) {
          final route = CreateReminderRoute.fromState(state);
          return BlocProvider<CreateReminderCubit>.value(
            value: resolveCreateReminderCubit(),
            child: CreateReminderScreen(
              reminder: route.reminder,
              initialType: route.initialType,
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
          return BlocProvider<PeopleCubit>.value(
            value: resolvePeopleCubit(),
            child: Scaffold(
              body: PeopleView(pendingInviteCode: route?.code),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.inviteJoinBase,
        builder: (context, state) {
          final route = JoinInviteRoute.fromUri(state.uri);
          return BlocProvider<PeopleCubit>.value(
            value: resolvePeopleCubit(),
            child: Scaffold(
              body: PeopleView(pendingInviteCode: route?.code),
            ),
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
                builder: (context, state) => BlocProvider<HomeCubit>.value(
                  value: resolveHomeCubit(),
                  child: const HomeView(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.people,
                builder: (context, state) => BlocProvider<PeopleCubit>.value(
                  value: resolvePeopleCubit(),
                  child: PeopleView(
                    pendingInviteCode:
                        state.uri.queryParameters[AppRoutes.inviteCodeParam],
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reminders,
                builder: (context, state) => BlocProvider<RemindersCubit>.value(
                  value: resolveRemindersCubit(),
                  child: const RemindersView(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.account,
                builder: (context, state) => BlocProvider<AccountCubit>.value(
                  value: resolveAccountCubit(),
                  child: const AccountView(),
                ),
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

CreateReminderCubit _defaultCreateReminderCubitFactory() =>
    slInstance<CreateReminderCubit>(instanceName: 'createReminderCubit');

/// Sign-up is a one-shot form with no shared tab state: each visit gets a
/// fresh cubit built from the global [AuthService].
SignUpCubit _defaultSignUpCubitFactory() => SignUpCubit(
  slInstance<AuthService>(instanceName: 'authService'),
);

/// Invites are one-shot sends: each visit gets a fresh cubit built from
/// the global [EdgetFunctions] client.
InvitePeopleCubit _defaultInvitePeopleCubitFactory() => InvitePeopleCubit(
  edgetFunctions: slInstance<EdgetFunctions>(instanceName: 'edgetFunctions'),
);

FamilySettingsCubit _defaultFamilySettingsCubitFactory() =>
    slInstance<FamilySettingsCubit>(instanceName: 'familySettingsCubit');

NotificationSettingsCubit _defaultNotificationSettingsCubitFactory() =>
    slInstance<NotificationSettingsCubit>(
      instanceName: 'notificationSettingsCubit',
    );

ManageProfileCubit _defaultManageProfileCubitFactory() =>
    slInstance<ManageProfileCubit>(instanceName: 'manageProfileCubit');

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
