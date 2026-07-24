import 'package:go_router/go_router.dart';
import 'package:vita_folder_mobile/core/router/main_shell.dart';
import 'package:vita_folder_mobile/features/account/presentation/views/account_view.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/home_view.dart';
import 'package:vita_folder_mobile/features/login/presentation/views/sign_up_screen.dart';
import 'package:vita_folder_mobile/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:vita_folder_mobile/features/people/presentation/views/invite_people_screen.dart';
import 'package:vita_folder_mobile/features/people/presentation/views/people_view.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/screens/reminders_view.dart';

GoRouter createRouter({required bool onboardingCompleted}) {
  return GoRouter(
    initialLocation: onboardingCompleted ? '/home' : '/onboarding',
    routes: [
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpView(),
      ),
      GoRoute(
        path: '/invite-people',
        builder: (context, state) => const InvitePeopleScreen(),
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
