import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:house_mira_core/auth/google_sign_in_handler.dart';
import 'package:house_mira_core/observability/app_logger.dart';
import 'package:house_mira_core/observability/crash_reporter.dart';
import 'package:mocktail/mocktail.dart';

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class _MockAuthorizationClient extends Mock
    implements GoogleSignInAuthorizationClient {}

class _FakeCrashReporter implements CrashReporter {
  final logs = <String>[];
  final errors = <Object>[];
  final reasons = <String?>[];
  final contexts = <Map<String, Object?>?>[];

  @override
  Future<void> log(String message) async {
    logs.add(message);
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, Object?>? context,
    bool fatal = false,
  }) async {
    errors.add(error);
    reasons.add(reason);
    contexts.add(context);
  }

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}
}

const _serverClientId = 'server-client-id';

void main() {
  late _MockGoogleSignIn googleSignIn;
  late _MockGoogleSignInAccount account;
  late _MockAuthorizationClient authorizationClient;
  late _FakeCrashReporter crashReporter;
  late AppLogger logger;

  setUp(() {
    googleSignIn = _MockGoogleSignIn();
    account = _MockGoogleSignInAccount();
    authorizationClient = _MockAuthorizationClient();

    when(
      () => googleSignIn.initialize(
        clientId: any(named: 'clientId'),
        serverClientId: any(named: 'serverClientId'),
      ),
    ).thenAnswer((_) async {});
    when(() => account.email).thenReturn('user@example.com');
    when(
      () => account.authentication,
    ).thenReturn(const GoogleSignInAuthentication(idToken: 'id-token'));
    when(() => account.authorizationClient).thenReturn(authorizationClient);
    when(
      () => authorizationClient.authorizationForScopes(any()),
    ).thenAnswer(
      (_) async => const GoogleSignInClientAuthorization(accessToken: 'access'),
    );
    when(() => authorizationClient.authorizeScopes(any())).thenAnswer(
      (_) async => const GoogleSignInClientAuthorization(accessToken: 'access'),
    );

    crashReporter = _FakeCrashReporter();
    logger = AppLogger(crashReporter: crashReporter);
  });

  GoogleSignInHandler buildHandler() => GoogleSignInHandler(
    googleSignIn: googleSignIn,
    serverClientId: _serverClientId,
    logger: logger,
  );

  group('GoogleSignInHandler', () {
    test('restores a previous session without showing UI', () async {
      when(
        () => googleSignIn.attemptLightweightAuthentication(),
      ).thenAnswer((_) async => account);

      final tokens = await buildHandler().signIn();

      expect(tokens?.idToken, 'id-token');
      expect(tokens?.accessToken, 'access');
      verifyNever(() => googleSignIn.authenticate());
    });

    test(
      'falls back to the interactive flow when there is no session',
      () async {
        when(
          () => googleSignIn.attemptLightweightAuthentication(),
        ).thenAnswer((_) async => null);
        when(
          () => googleSignIn.authenticate(),
        ).thenAnswer((_) async => account);

        final tokens = await buildHandler().signIn();

        expect(tokens?.idToken, 'id-token');
        verify(() => googleSignIn.authenticate()).called(1);
      },
    );

    test(
      'falls back to the interactive flow when the lightweight attempt fails',
      () async {
        // Regression: a transient error while restoring a previous session
        // must not abort the sign-in before the account picker is shown.
        when(
          () => googleSignIn.attemptLightweightAuthentication(),
        ).thenAnswer(
          (_) => Future<GoogleSignInAccount?>.error(
            const GoogleSignInException(
              code: GoogleSignInExceptionCode.providerConfigurationError,
              description: 'provider misconfigured',
            ),
          ),
        );
        when(
          () => googleSignIn.authenticate(),
        ).thenAnswer((_) async => account);

        final tokens = await buildHandler().signIn();

        expect(tokens?.idToken, 'id-token');
        verify(() => googleSignIn.authenticate()).called(1);
      },
    );

    test(
      'falls back to the interactive flow when the lightweight attempt throws '
      'a non-Google error',
      () async {
        when(
          () => googleSignIn.attemptLightweightAuthentication(),
        ).thenThrow(Exception('boom'));
        when(
          () => googleSignIn.authenticate(),
        ).thenAnswer((_) async => account);

        final tokens = await buildHandler().signIn();

        expect(tokens?.idToken, 'id-token');
        verify(() => googleSignIn.authenticate()).called(1);
      },
    );

    test('reports the lightweight failure to Crashlytics', () async {
      when(
        () => googleSignIn.attemptLightweightAuthentication(),
      ).thenAnswer(
        (_) => Future<GoogleSignInAccount?>.error(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.providerConfigurationError,
            description: 'provider misconfigured',
          ),
        ),
      );
      when(() => googleSignIn.authenticate()).thenAnswer((_) async => account);

      await buildHandler().signIn();
      await Future<void>.delayed(Duration.zero);

      expect(crashReporter.errors, hasLength(1));
      expect(
        crashReporter.reasons.single,
        contains('lightweight sign-in failed'),
      );
      expect(
        crashReporter.contexts.single?['code'],
        'providerConfigurationError',
      );
    });

    test(
      'propagates the interactive failure when the lightweight attempt failed',
      () async {
        when(
          () => googleSignIn.attemptLightweightAuthentication(),
        ).thenAnswer(
          (_) => Future<GoogleSignInAccount?>.error(
            const GoogleSignInException(
              code: GoogleSignInExceptionCode.providerConfigurationError,
            ),
          ),
        );
        when(() => googleSignIn.authenticate()).thenAnswer(
          (_) => Future<GoogleSignInAccount>.error(
            const GoogleSignInException(
              code: GoogleSignInExceptionCode.clientConfigurationError,
            ),
          ),
        );

        await expectLater(
          buildHandler().signIn(),
          throwsA(
            isA<GoogleSignInException>().having(
              (e) => e.code,
              'code',
              GoogleSignInExceptionCode.clientConfigurationError,
            ),
          ),
        );
      },
    );

    test('returns null when the interactive flow is canceled', () async {
      when(
        () => googleSignIn.attemptLightweightAuthentication(),
      ).thenAnswer((_) async => null);
      when(() => googleSignIn.authenticate()).thenAnswer(
        (_) => Future<GoogleSignInAccount>.error(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.canceled,
          ),
        ),
      );

      expect(await buildHandler().signIn(), isNull);
    });

    test('throws when Google returns no ID token', () async {
      when(
        () => googleSignIn.attemptLightweightAuthentication(),
      ).thenAnswer((_) async => null);
      when(() => googleSignIn.authenticate()).thenAnswer((_) async => account);
      when(
        () => account.authentication,
      ).thenReturn(const GoogleSignInAuthentication(idToken: null));

      await expectLater(
        buildHandler().signIn(),
        throwsA(isA<GoogleSignInException>()),
      );
    });

    test('reports a failed scope authorization', () async {
      when(
        () => googleSignIn.attemptLightweightAuthentication(),
      ).thenAnswer((_) async => account);
      when(
        () => authorizationClient.authorizationForScopes(any()),
      ).thenThrow(Exception('no scope'));

      await expectLater(
        buildHandler().signIn(),
        throwsA(isA<Exception>()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(crashReporter.errors, hasLength(1));
    });

    test('sign-out never throws', () async {
      when(() => googleSignIn.signOut()).thenThrow(Exception('boom'));

      await buildHandler().signOut();
    });
  });
}
