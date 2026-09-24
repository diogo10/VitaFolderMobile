import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/auth/auth_state_notifier.dart';
import 'package:house_mira/core/router/app_routes.dart';
import 'package:house_mira/core/router/main_shell.dart';
import 'package:house_mira/core/router/splash_view.dart';
import 'package:house_mira/features/account/presentation/views/account_view.dart';
import 'package:house_mira/features/account/presentation/views/manage_profile_screen.dart';
import 'package:house_mira/features/account/presentation/views/notification_settings_screen.dart';
import 'package:house_mira/features/home/presentation/views/home_view.dart';
import 'package:house_mira/features/login/presentation/views/sign_up_screen.dart';
import 'package:house_mira/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:house_mira/features/people/presentation/views/family_settings_screen.dart';
import 'package:house_mira/features/people/presentation/views/invite_people_screen.dart';
import 'package:house_mira/features/people/presentation/views/people_view.dart';
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
GoRouter createRouter({
  required bool onboardingCompleted,
  AuthStateNotifier? authStateNotifier,
  List<NavigatorObserver>? observers,
  String? initialLocation,
}) {
  final notifier = authStateNotifier;
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
        builder: (context, state) => const SignUpView(),
      ),
      GoRoute(
        path: AppRoutes.invitePeople,
        builder: (context, state) {
          final route = InvitePeopleRoute.fromState(state);
          return InvitePeopleScreen(
            familyName: route.familyName,
            inviteCode: route.inviteCode,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.manageProfile,
        builder: (context, state) => const ManageProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.familySettings,
        builder: (context, state) => const FamilySettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.createReminder,
        builder: (context, state) {
          final route = CreateReminderRoute.fromState(state);
          return CreateReminderScreen(
            reminder: route.reminder,
            initialType: route.initialType,
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
          return Scaffold(
            body: PeopleView(pendingInviteCode: route?.code),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.inviteJoinBase,
        builder: (context, state) {
          final route = JoinInviteRoute.fromUri(state.uri);
          return Scaffold(
            body: PeopleView(pendingInviteCode: route?.code),
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
                builder: (context, state) => const HomeView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.people,
                builder: (context, state) => PeopleView(
                  pendingInviteCode:
                      state.uri.queryParameters[AppRoutes.inviteCodeParam],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reminders,
                builder: (context, state) => const RemindersView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.account,
                builder: (context, state) => const AccountView(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

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
