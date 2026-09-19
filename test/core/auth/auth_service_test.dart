import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/auth/google_sign_in_handler.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockAuthResponse extends Mock implements AuthResponse {}

class _MockUserResponse extends Mock implements UserResponse {}

class _MockGoogleSignInHandler extends Mock implements IGoogleSignInHandler {}

class _MockFunctionsClient extends Mock implements FunctionsClient {}

/// Fake postgrest filter builder that resolves the configured rows
/// (or throws the configured error) when awaited. Avoids stubbing
/// `Future.then` on a mock, which mocktail does not support.
class _FakePostgrestFilter<T> extends Fake
    implements PostgrestFilterBuilder<T> {
  _FakePostgrestFilter.value(this._value) : _error = null;
  _FakePostgrestFilter.error(this._error) : _value = null;

  final T? _value;
  final Object? _error;

  Future<T> get _future {
    if (_error != null) return Future<T>.error(_error);
    return Future<T>.value(_value as T);
  }

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(T value) onValue, {
    Function? onError,
  }) => _future.then(onValue, onError: onError);

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) =>
      _future.catchError(onError, test: test);

  @override
  Future<T> whenComplete(FutureOr<dynamic> Function() action) =>
      _future.whenComplete(action);

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Stream<T> asStream() => _future.asStream();
}

/// Fake query builder returning pre-configured filter builders.
class _FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeSupabaseQueryBuilder({this.selectResult, this.updateResult});

  final PostgrestFilterBuilder<PostgrestList>? selectResult;
  final PostgrestFilterBuilder<dynamic>? updateResult;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    final result = selectResult;
    if (result == null) throw UnimplementedError('select not stubbed');
    return result;
  }

  @override
  PostgrestFilterBuilder<dynamic> update(Map<dynamic, dynamic> values) {
    final result = updateResult;
    if (result == null) throw UnimplementedError('update not stubbed');
    return result;
  }
}

User _user({String id = 'u1', String? email = 'a@b.c'}) {
  final json = <String, dynamic>{'id': id};
  if (email != null) json['email'] = email;
  final user = User.fromJson(json);
  if (user == null) throw StateError('Failed to build test user');
  return user;
}

/// Stubs `from('profiles').select(...).eq(...)` to resolve with [rows].
void _stubSelectEq({
  required _MockSupabaseClient supabase,
  required PostgrestList rows,
}) {
  when(() => supabase.from('profiles')).thenAnswer(
    (_) => _FakeSupabaseQueryBuilder(
      selectResult: _FakePostgrestFilter<PostgrestList>.value(rows),
    ),
  );
}

/// Stubs `from('profiles').select(...).eq(...)` to throw [error] on await.
void _stubSelectError({
  required _MockSupabaseClient supabase,
  required Object error,
}) {
  when(() => supabase.from('profiles')).thenAnswer(
    (_) => _FakeSupabaseQueryBuilder(
      selectResult: _FakePostgrestFilter<PostgrestList>.error(error),
    ),
  );
}

/// Stubs `from('profiles').update(...).eq(...)` to complete successfully.
void _stubUpdateEq({required _MockSupabaseClient supabase}) {
  when(() => supabase.from('profiles')).thenAnswer(
    (_) => _FakeSupabaseQueryBuilder(
      updateResult: _FakePostgrestFilter<dynamic>.value(<String, dynamic>{}),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(OAuthProvider.google);
    registerFallbackValue(UserAttributes(data: const {}));
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

  group('currentUser / isLoggedIn / currentUserId', () {
    test('exposes the current user when signed in', () {
      final user = _user();
      when(() => auth.currentUser).thenReturn(user);

      final service = build();

      expect(service.currentUser?.id, 'u1');
      expect(service.isLoggedIn(), isTrue);
      expect(service.currentUserId, 'u1');
    });

    test('reports signed out when there is no current user', () {
      when(() => auth.currentUser).thenReturn(null);

      final service = build();

      expect(service.currentUser, isNull);
      expect(service.isLoggedIn(), isFalse);
      expect(service.currentUserId, isNull);
    });
  });

  group('AuthService.signUp', () {
    test('returns the user on successful sign-up', () async {
      final response = _MockAuthResponse();
      when(() => response.user).thenReturn(_user());
      when(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);
      when(() => auth.currentUser).thenReturn(_user());
      _stubUpdateEq(supabase: supabase);

      final user = await build().signUp(
        email: 'a@b.c',
        password: 'secret',
        name: 'Ada',
      );

      expect(user?.id, 'u1');
      verify(
        () => auth.signUp(
          email: 'a@b.c',
          password: 'secret',
          data: {'full_name': 'Ada'},
        ),
      ).called(1);
      verify(() => supabase.from('profiles')).called(1);
    });

    test('ensures the profile with name and email on sign-up', () async {
      final response = _MockAuthResponse();
      when(() => response.user).thenReturn(_user(email: null));
      when(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);
      when(() => auth.currentUser).thenReturn(_user(email: null));
      _stubUpdateEq(supabase: supabase);

      final user = await build().signUp(
        email: 'a@b.c',
        password: 'secret',
        name: 'Ada',
      );

      expect(user?.id, 'u1');
      verify(() => supabase.from('profiles')).called(1);
    });

    test('throws AuthException when sign-up returns no user', () async {
      final response = _MockAuthResponse();
      when(() => response.user).thenReturn(null);
      when(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      expect(
        () => build().signUp(email: 'a@b.c', password: 'x', name: 'Ada'),
        throwsA(isA<AuthException>()),
      );
    });

    test('propagates AuthException (e.g. email already registered)', () async {
      when(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenThrow(const AuthException('User already registered'));

      expect(
        () => build().signUp(email: 'a@b.c', password: 'x', name: 'Ada'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'User already registered',
          ),
        ),
      );
    });

    test('propagates network failures', () async {
      when(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenThrow(const AuthException('Network request failed'));

      expect(
        () => build().signUp(email: 'a@b.c', password: 'x', name: 'Ada'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService.signIn (email/password)', () {
    test('completes on successful login', () async {
      final response = _MockAuthResponse();
      when(() => response.user).thenReturn(_user());
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => response);

      await build().signIn(email: 'a@b.c', password: 'secret');

      verify(
        () => auth.signInWithPassword(email: 'a@b.c', password: 'secret'),
      ).called(1);
    });

    test('throws AuthException when no user is returned', () async {
      final response = _MockAuthResponse();
      when(() => response.user).thenReturn(null);
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => response);

      expect(
        () => build().signIn(email: 'a@b.c', password: 'wrong'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Invalid email or password.',
          ),
        ),
      );
    });

    test('propagates invalid credentials from Supabase', () async {
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('Invalid login credentials'));

      expect(
        () => build().signIn(email: 'a@b.c', password: 'wrong'),
        throwsA(isA<AuthException>()),
      );
    });

    test('propagates network failures', () async {
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('Network request failed'));

      expect(
        () => build().signIn(email: 'a@b.c', password: 'secret'),
        throwsA(isA<AuthException>()),
      );
    });
  });

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
      when(() => googleHandler.signIn()).thenAnswer(
        (_) async => const GoogleAuthTokens(
          idToken: 'google-id-token',
          accessToken: 'google-access-token',
        ),
      );
      _stubUpdateEq(supabase: supabase);

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

    test('ensures the profile email on Google sign-in', () async {
      final googleUser = User.fromJson({
        'id': 'u1',
        'email': 'g@example.com',
        'user_metadata': {
          'full_name': 'Google User',
          'avatar_url': 'http://example.com/a.png',
        },
      });
      if (googleUser == null) throw StateError('Failed to build user');
      final response = _MockAuthResponse();
      when(() => response.user).thenReturn(googleUser);
      when(
        () => auth.signInWithIdToken(
          provider: any(named: 'provider'),
          idToken: any(named: 'idToken'),
          accessToken: any(named: 'accessToken'),
        ),
      ).thenAnswer((_) async => response);
      when(() => googleHandler.signIn()).thenAnswer(
        (_) async => const GoogleAuthTokens(idToken: 'token'),
      );
      _stubUpdateEq(supabase: supabase);

      final user = await build().signInWithGoogle();

      expect(user?.email, 'g@example.com');
      verify(() => supabase.from('profiles')).called(1);
    });

    test('exchanges the token even without a Google access token', () async {
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
      ).thenAnswer((_) async => const GoogleAuthTokens(idToken: 'token'));

      final user = await build().signInWithGoogle();

      expect(user?.id, 'u1');
      verify(
        () => auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: 'token',
          // ignore: avoid_redundant_argument_values, explicitly asserting null
          accessToken: null,
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

    test(
      'falls back to a default message when the description is missing',
      () async {
        when(() => googleHandler.signIn()).thenThrow(
          const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
        );

        expect(
          () => build().signInWithGoogle(),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'Google sign-in failed.',
            ),
          ),
        );
      },
    );

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

      expect(() => build().signInWithGoogle(), throwsA(isA<AuthException>()));
    });

    test('propagates network failures during the token exchange', () async {
      when(
        () => googleHandler.signIn(),
      ).thenAnswer((_) async => const GoogleAuthTokens(idToken: 'token'));
      when(
        () => auth.signInWithIdToken(
          provider: any(named: 'provider'),
          idToken: any(named: 'idToken'),
          accessToken: any(named: 'accessToken'),
        ),
      ).thenThrow(const AuthException('Network request failed'));

      expect(() => build().signInWithGoogle(), throwsA(isA<AuthException>()));
    });
  });

  group('AuthService passwords', () {
    test('triggerForgetPassword forwards the email', () async {
      when(() => auth.resetPasswordForEmail(any())).thenAnswer((_) async {});

      await build().triggerForgetPassword(email: 'a@b.c');

      verify(() => auth.resetPasswordForEmail('a@b.c')).called(1);
    });

    test('triggerForgetPassword propagates network failures', () async {
      when(
        () => auth.resetPasswordForEmail(any()),
      ).thenThrow(const AuthException('Network request failed'));

      expect(
        () => build().triggerForgetPassword(email: 'a@b.c'),
        throwsA(isA<AuthException>()),
      );
    });

    test('resetPassword trims the email and sets the redirect', () async {
      when(
        () => auth.resetPasswordForEmail(
          any(),
          redirectTo: any(named: 'redirectTo'),
        ),
      ).thenAnswer((_) async {});

      await build().resetPassword('  a@b.c  ');

      verify(
        () => auth.resetPasswordForEmail(
          'a@b.c',
          redirectTo: 'http://example.com/account/update-password',
        ),
      ).called(1);
    });

    test('resetPassword propagates network failures', () async {
      when(
        () => auth.resetPasswordForEmail(
          any(),
          redirectTo: any(named: 'redirectTo'),
        ),
      ).thenThrow(const AuthException('Network request failed'));

      expect(
        () => build().resetPassword('a@b.c'),
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

    test('propagates Supabase sign-out failures', () async {
      when(() => googleHandler.signOut()).thenAnswer((_) async {});
      when(
        () => auth.signOut(),
      ).thenThrow(const AuthException('Network error'));

      expect(() => build().signOut(), throwsA(isA<AuthException>()));
    });
  });

  group('AuthService.updateName', () {
    test('throws when not signed in', () async {
      when(() => auth.currentUser).thenReturn(null);

      expect(
        () => build().updateName('Ada'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Not signed in.',
          ),
        ),
      );
    });

    test('updates the profile row and the auth metadata', () async {
      when(() => auth.currentUser).thenReturn(_user());
      _stubUpdateEq(supabase: supabase);
      final userResponse = _MockUserResponse();
      when(() => userResponse.user).thenReturn(_user());
      when(() => auth.updateUser(any())).thenAnswer((_) async => userResponse);

      await build().updateName('Ada Lovelace');

      verify(() => supabase.from('profiles')).called(1);
      verify(() => auth.updateUser(any(that: isA<UserAttributes>()))).called(1);
    });

    test('propagates network failures', () async {
      when(() => auth.currentUser).thenReturn(_user());
      when(() => supabase.from(any())).thenThrow(Exception('Network error'));

      expect(() => build().updateName('Ada'), throwsException);
    });
  });

  group('AuthService.getProfileName', () {
    test('returns null when not signed in', () async {
      when(() => auth.currentUser).thenReturn(null);

      expect(await build().getProfileName(), isNull);
      verifyNever(() => supabase.from(any()));
    });

    test('returns the profile full_name on success', () async {
      when(() => auth.currentUser).thenReturn(_user());
      _stubSelectEq(
        supabase: supabase,
        rows: [
          {'full_name': 'Ada Lovelace'},
        ],
      );

      expect(await build().getProfileName(), 'Ada Lovelace');
    });

    test('returns null when the profile row is missing', () async {
      when(() => auth.currentUser).thenReturn(_user());
      _stubSelectEq(supabase: supabase, rows: <Map<String, dynamic>>[]);

      expect(await build().getProfileName(), isNull);
    });

    test('returns null on network failure', () async {
      when(() => auth.currentUser).thenReturn(_user());
      _stubSelectError(supabase: supabase, error: Exception('Network error'));

      expect(await build().getProfileName(), isNull);
    });
  });

  group('AuthService.deleteAccount', () {
    late _MockFunctionsClient functions;

    setUp(() {
      functions = _MockFunctionsClient();
      when(() => supabase.functions).thenReturn(functions);
    });

    void stubInvokeSuccess() {
      when(() => functions.invoke(any())).thenAnswer(
        (_) async => const FunctionResponse(
          data: {'success': true},
          status: 200,
        ),
      );
    }

    test('invokes the delete-account edge function when signed in', () async {
      when(() => auth.currentUser).thenReturn(_user());
      stubInvokeSuccess();

      await build().deleteAccount();

      verify(() => functions.invoke('delete-account')).called(1);
    });

    test('throws AuthException without invoking when not signed in', () async {
      when(() => auth.currentUser).thenReturn(null);

      expect(
        () => build().deleteAccount(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Not signed in.',
          ),
        ),
      );
      verifyNever(() => functions.invoke(any()));
    });

    test('maps a 409 sole_owner response to SoleOwnerException', () async {
      when(() => auth.currentUser).thenReturn(_user());
      when(() => functions.invoke(any())).thenThrow(
        const FunctionException(
          status: 409,
          details: {'code': 'sole_owner', 'family_id': 'family-1'},
        ),
      );

      expect(
        () => build().deleteAccount(),
        throwsA(
          isA<SoleOwnerException>().having(
            (e) => e.familyId,
            'familyId',
            'family-1',
          ),
        ),
      );
    });

    test('maps server failures to DeleteAccountException', () async {
      when(() => auth.currentUser).thenReturn(_user());
      when(() => functions.invoke(any())).thenThrow(
        const FunctionException(
          status: 500,
          details: {'code': 'delete_failed'},
        ),
      );

      expect(
        () => build().deleteAccount(),
        throwsA(isA<DeleteAccountException>()),
      );
    });

    test('maps 401 to AuthException', () async {
      when(() => auth.currentUser).thenReturn(_user());
      when(() => functions.invoke(any())).thenThrow(
        const FunctionException(status: 401, details: {'code': 'unauthorized'}),
      );

      expect(() => build().deleteAccount(), throwsA(isA<AuthException>()));
    });
  });

  group('AuthService.getAsPersonEntity', () {
    test('returns the person entity on success', () async {
      when(() => auth.currentUser).thenReturn(_user());
      _stubSelectEq(
        supabase: supabase,
        rows: [
          {
            'id': 'u1',
            'full_name': 'Ada Lovelace',
            'email': 'a@b.c',
            'phone': null,
            'role': 'owner',
          },
        ],
      );

      final person = await build().getAsPersonEntity();

      expect(
        person,
        const PersonEntity(
          id: 'u1',
          name: 'Ada Lovelace',
          email: 'a@b.c',
          role: 'owner',
        ),
      );
    });

    test('returns null on network failure', () async {
      when(() => auth.currentUser).thenReturn(_user());
      _stubSelectError(supabase: supabase, error: Exception('Network error'));

      expect(await build().getAsPersonEntity(), isNull);
    });
  });
}
