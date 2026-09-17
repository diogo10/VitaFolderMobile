import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/auth/google_sign_in_handler.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockAuthResponse extends Mock implements AuthResponse {}

class _MockGoogleSignInHandler extends Mock implements IGoogleSignInHandler {}

User _user() => User.fromJson({'id': 'u1', 'email': 'a@b.c'})!;

void main() {
  setUpAll(() {
    registerFallbackValue(OAuthProvider.google);
  });

  late _MockSupabaseClient supabase;
  late _MockGoTrueClient auth;
  late _MockGoogleSignInHandler googleHandler;

  setUp(() {
    supabase = _MockSupabaseClient();
    auth = _MockGoTrueClient();
    googleHandler = _MockGoogleSignInHandler();
    when(() => supabase.auth).thenReturn(auth);
  });

  AuthService build() => AuthService(
    supabaseClient: supabase,
    googleSignInHandler: googleHandler,
  );

  group('AuthService.signInWithGoogle', () {
    test('exchanges the Google ID token for a Supabase session', () async {
      final response = _MockAuthResponse();
      when(() => response.user).thenReturn(_user());
      when(
        () => auth.signInWithIdToken(
          provider: any(named: 'provider'),
          idToken: any(named: 'idToken'),
          accessToken: any(named: 'accessToken'),
        ),
      ).thenAnswer((_) async => response);
      when(
        () => googleHandler.signIn(),
      ).thenAnswer(
        (_) async => const GoogleAuthTokens(
          idToken: 'google-id-token',
          accessToken: 'google-access-token',
        ),
      );

      final user = await build().signInWithGoogle();

      expect(user?.id, 'u1');
      verify(
        () => auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: 'google-id-token',
          accessToken: 'google-access-token',
        ),
      ).called(1);
    });

    test('returns null without exchanging when the user cancels', () async {
      when(() => googleHandler.signIn()).thenAnswer((_) async => null);

      final user = await build().signInWithGoogle();

      expect(user, isNull);
      verifyNever(
        () => auth.signInWithIdToken(
          provider: any(named: 'provider'),
          idToken: any(named: 'idToken'),
        ),
      );
    });

    test('throws AuthException when Google sign-in fails', () async {
      when(() => googleHandler.signIn()).thenThrow(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
          description: 'No ID Token found.',
        ),
      );

      expect(
        () => build().signInWithGoogle(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'No ID Token found.',
          ),
        ),
      );
    });

    test('throws AuthException when the exchange returns no user', () async {
      final response = _MockAuthResponse();
      when(() => response.user).thenReturn(null);
      when(
        () => auth.signInWithIdToken(
          provider: any(named: 'provider'),
          idToken: any(named: 'idToken'),
          accessToken: any(named: 'accessToken'),
        ),
      ).thenAnswer((_) async => response);
      when(
        () => googleHandler.signIn(),
      ).thenAnswer((_) async => const GoogleAuthTokens(idToken: 'token'));

      expect(
        () => build().signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService.signOut', () {
    test('signs out from Google and Supabase', () async {
      when(() => googleHandler.signOut()).thenAnswer((_) async {});
      when(() => auth.signOut()).thenAnswer((_) async {});

      await build().signOut();

      verify(() => googleHandler.signOut()).called(1);
      verify(() => auth.signOut()).called(1);
    });
  });
}
