import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/auth/auth_state_notifier.dart';
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
import 'package:house_mira/features/reminders/domain/entities/reminder_entity.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
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
///
/// Guest usage is allowed: unauthenticated users can browse the main tabs
/// (each view renders its own signed-out empty state). Only the splash gate
/// and the signed-in-away-from-sign-up rule are enforced here.
GoRouter createRouter({
  required bool onboardingCompleted,
  AuthStateNotifier? authStateNotifier,
  List<NavigatorObserver>? observers,
}) {
  final notifier = authStateNotifier;
  return GoRouter(
    initialLocation: (notifier != null && !notifier.isInitialized)
        ? '/splash'
        : (onboardingCompleted ? '/home' : '/onboarding'),
    refreshListenable: notifier,
    redirect: (context, state) {
      if (notifier == null) {
        return null;
      }
      final location = state.uri.path;
      if (!notifier.isInitialized) {
        return location == '/splash' ? null : '/splash';
      }
      if (location == '/splash') {
        return onboardingCompleted ? '/home' : '/onboarding';
      }
      if (notifier.isAuthenticated && location == '/sign-up') {
        return '/home';
      }
      return null;
    },
    observers: observers ?? [],
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashView(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpView(),
      ),
      GoRoute(
        path: '/invite-people',
        builder: (context, state) => InvitePeopleScreen(
          familyName: state.extra is String ? state.extra! as String : null,
        ),
      ),
      GoRoute(
        path: '/manage-profile',
        builder: (context, state) => const ManageProfileScreen(),
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/family-settings',
        builder: (context, state) => const FamilySettingsScreen(),
      ),
      GoRoute(
        path: '/create-reminder',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is ReminderEntity) {
            return CreateReminderScreen(reminder: extra);
          }
          return CreateReminderScreen(
            initialType: extra is ReminderType ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/people',
                builder: (context, state) => const PeopleView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reminders',
                builder: (context, state) => const RemindersView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account',
                builder: (context, state) => const AccountView(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
