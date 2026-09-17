import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/auth/google_sign_in_handler.dart';
import 'package:house_mira/core/widgets/sand/google_g_icon.dart';
import 'package:house_mira/features/login/presentation/cubit/sign_up_cubit.dart';
import 'package:house_mira/features/login/presentation/views/sign_up_screen.dart';
import 'package:house_mira/generated/app_localizations.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoogleSignInHandler extends Mock implements IGoogleSignInHandler {}

class _FakeAuthService extends AuthService {
  _FakeAuthService()
    : super(
        supabaseClient: _MockSupabaseClient(),
        googleSignInHandler: _MockGoogleSignInHandler(),
      );

  String? lastSignUpEmail;
  String? lastSignUpPassword;
  String? lastSignUpName;
  bool shouldSucceed = true;

  @override
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    lastSignUpEmail = email;
    lastSignUpPassword = password;
    lastSignUpName = name;
    if (!shouldSucceed) {
      throw AuthException('Sign up failed');
    }
    return User.fromJson({'id': 'u1', 'email': email});
  }
}

void main() {
  late _FakeAuthService authService;

  setUp(() {
    authService = _FakeAuthService();
  });

  Future<void> pumpSignUp(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/sign-up',
      routes: [
        GoRoute(
          path: '/sign-up',
          builder: (context, state) => const SignUpView(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('home-shell')),
        ),
        GoRoute(
          path: '/account',
          builder: (context, state) =>
              const Scaffold(body: Text('account-shell')),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SignUpCubit>(create: (_) => SignUpCubit(authService)),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();
  }

  group('SignUpView', () {
    testWidgets('renders header, form and footer content', (tester) async {
      await pumpSignUp(tester);

      expect(find.text('HouseMira'), findsOneWidget);
      expect(
        find.textContaining('Join the circle,', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('start organizing.', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text(
          'Create your account and invite your family members to start collaborating today.',
        ),
        findsOneWidget,
      );

      expect(find.byType(GoogleGIcon), findsOneWidget);
      expect(find.text('Sign up with Google'), findsOneWidget);
      expect(find.text('OR EMAIL'), findsOneWidget);

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('you@example.com'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Create a strong password'), findsOneWidget);
      expect(
        find.text(
          'Must be at least 8 characters long with a mix of letters and numbers.',
        ),
        findsOneWidget,
      );

      expect(find.text('Create Account'), findsOneWidget);
      expect(
        find.textContaining('Already have an account?', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Sign In', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Terms of Service', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Privacy Policy', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('shows validation errors when submitting an empty form', (
      tester,
    ) async {
      await pumpSignUp(tester);

      await tester.ensureVisible(find.text('Create Account'));
      await tester.pump();
      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter an email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
      expect(authService.lastSignUpEmail, isNull);
    });

    testWidgets('calls signUp with entered credentials and navigates home', (
      tester,
    ) async {
      await pumpSignUp(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'John Doe');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'user@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'secret12');
      await tester.ensureVisible(find.text('Create Account'));
      await tester.pump();
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(authService.lastSignUpName, 'John Doe');
      expect(authService.lastSignUpEmail, 'user@example.com');
      expect(authService.lastSignUpPassword, 'secret12');
      expect(find.text('home-shell'), findsOneWidget);
    });

    testWidgets('shows error snackbar when sign up fails', (tester) async {
      authService.shouldSucceed = false;
      await pumpSignUp(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'John Doe');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'user@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'secret12');
      await tester.ensureVisible(find.text('Create Account'));
      await tester.pump();
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Sign up failed'), findsOneWidget);
      expect(find.text('home-shell'), findsNothing);
    });

    testWidgets('navigates to account when tapping Sign In', (tester) async {
      await pumpSignUp(tester);

      await tester.ensureVisible(
        find.textContaining('Sign In', findRichText: true),
      );
      await tester.pump();
      await tester.tap(find.textContaining('Sign In', findRichText: true));
      await tester.pumpAndSettle();

      expect(find.text('account-shell'), findsOneWidget);
    });
  });
}
