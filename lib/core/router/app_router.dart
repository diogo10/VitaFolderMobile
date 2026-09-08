import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/router/main_shell.dart';
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

GoRouter createRouter({
  required bool onboardingCompleted,
  List<NavigatorObserver>? observers,
}) {
  return GoRouter(
    initialLocation: onboardingCompleted ? '/home' : '/onboarding',
    observers: observers ?? [],
    routes: [
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpView(),
      ),
      GoRoute(
        path: '/invite-people',
        builder: (context, state) => InvitePeopleScreen(
          familyName: state.extra is String ? state.extra as String : null,
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
