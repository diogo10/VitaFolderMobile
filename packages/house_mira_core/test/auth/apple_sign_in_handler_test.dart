import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira_core/auth/apple_sign_in_handler.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

AuthorizationCredentialAppleID _credential({
  String? identityToken = 'apple-identity-token',
  String authorizationCode = 'apple-authorization-code',
  String? givenName,
  String? familyName,
  String? email,
}) {
  return AuthorizationCredentialAppleID(
    userIdentifier: 'apple-user-identifier',
    givenName: givenName,
    familyName: familyName,
    authorizationCode: authorizationCode,
    email: email,
    identityToken: identityToken,
    state: null,
  );
}

void main() {
  group('AppleSignInHandler', () {
    test('returns the identity token and the raw nonce', () async {
      List<AppleIDAuthorizationScopes>? requestedScopes;
      final handler = AppleSignInHandler(
        credentialProvider: ({required scopes, nonce}) async {
          requestedScopes = scopes;
          return _credential();
        },
      );

      final credentials = await handler.signIn();

      expect(credentials, isNotNull);
      expect(credentials!.identityToken, 'apple-identity-token');
      expect(credentials.authorizationCode, 'apple-authorization-code');
      expect(requestedScopes, [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ]);
    });

    test('sends the hashed nonce to Apple and keeps the raw one', () async {
      String? requestedNonce;
      final handler = AppleSignInHandler(
        credentialProvider: ({required scopes, nonce}) async {
          requestedNonce = nonce;
          return _credential();
        },
      );

      final credentials = await handler.signIn();

      expect(
        requestedNonce,
        sha256.convert(utf8.encode(credentials!.nonce)).toString(),
      );
    });

    test('generates a fresh nonce per attempt', () async {
      final handler = AppleSignInHandler(
        credentialProvider: ({required scopes, nonce}) async => _credential(),
      );

      final first = await handler.signIn();
      final second = await handler.signIn();

      expect(first!.nonce, isNot(second!.nonce));
    });

    test('returns null when the user cancels', () async {
      final handler = AppleSignInHandler(
        credentialProvider: ({required scopes, nonce}) async {
          throw const SignInWithAppleAuthorizationException(
            code: AuthorizationErrorCode.canceled,
            message: 'User canceled authorization',
          );
        },
      );

      expect(await handler.signIn(), isNull);
    });

    test('throws when the platform does not support Sign in with Apple', () {
      final handler = AppleSignInHandler(
        credentialProvider: ({required scopes, nonce}) async {
          throw const SignInWithAppleNotSupportedException(
            message: 'not supported',
          );
        },
      );

      expect(
        handler.signIn(),
        throwsA(
          isA<AppleSignInException>().having(
            (e) => e.code,
            'code',
            AppleSignInErrorCode.notSupported,
          ),
        ),
      );
    });

    test('throws when the authorization fails', () {
      final handler = AppleSignInHandler(
        credentialProvider: ({required scopes, nonce}) async {
          throw const SignInWithAppleAuthorizationException(
            code: AuthorizationErrorCode.failed,
            message: 'authorization failed',
          );
        },
      );

      expect(
        handler.signIn(),
        throwsA(
          isA<AppleSignInException>()
              .having(
                (e) => e.code,
                'code',
                AppleSignInErrorCode.failed,
              )
              .having((e) => e.detail, 'detail', 'authorization failed'),
        ),
      );
    });

    test('throws when the platform fails unexpectedly', () {
      final handler = AppleSignInHandler(
        credentialProvider: ({required scopes, nonce}) async {
          throw Exception('boom');
        },
      );

      expect(
        handler.signIn(),
        throwsA(
          isA<AppleSignInException>().having(
            (e) => e.code,
            'code',
            AppleSignInErrorCode.failed,
          ),
        ),
      );
    });

    test('throws when Apple returns no identity token', () {
      final handler = AppleSignInHandler(
        credentialProvider: ({required scopes, nonce}) async =>
            _credential(identityToken: null),
      );

      expect(
        handler.signIn(),
        throwsA(
          isA<AppleSignInException>().having(
            (e) => e.code,
            'code',
            AppleSignInErrorCode.missingIdentityToken,
          ),
        ),
      );
    });

    test('exposes the full name of the first authorization', () async {
      final handler = AppleSignInHandler(
        credentialProvider: ({required scopes, nonce}) async => _credential(
          givenName: 'Ada',
          familyName: 'Lovelace',
          email: 'ada@example.com',
        ),
      );

      final credentials = await handler.signIn();

      expect(credentials!.fullName, 'Ada Lovelace');
      expect(credentials.givenName, 'Ada');
      expect(credentials.familyName, 'Lovelace');
      expect(credentials.email, 'ada@example.com');
    });

    test('has no full name when Apple returns only a given name', () async {
      final handler = AppleSignInHandler(
        credentialProvider: ({required scopes, nonce}) async =>
            _credential(givenName: 'Ada'),
      );

      final credentials = await handler.signIn();

      expect(credentials!.fullName, 'Ada');
    });

    test('has no full name when Apple returns no name', () async {
      final handler = AppleSignInHandler(
        credentialProvider: ({required scopes, nonce}) async => _credential(),
      );

      final credentials = await handler.signIn();

      expect(credentials!.fullName, isNull);
    });

    test('sign-out never throws', () async {
      final handler = AppleSignInHandler(
        credentialProvider: ({required scopes, nonce}) async => _credential(),
      );

      await handler.signOut();
    });

    test('requests the credential from the plugin by default', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const channel = MethodChannel(
        'com.aboutyou.dart_packages.sign_in_with_apple',
      );
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return <String, dynamic>{
              'type': 'appleid',
              'userIdentifier': 'apple-user-identifier',
              'givenName': 'Ada',
              'familyName': 'Lovelace',
              'email': 'ada@example.com',
              'authorizationCode': 'apple-authorization-code',
              'identityToken': 'apple-identity-token',
              'state': null,
            };
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final credentials = await AppleSignInHandler().signIn();

      expect(credentials!.identityToken, 'apple-identity-token');
      expect(credentials.fullName, 'Ada Lovelace');
      expect(calls.single.method, 'performAuthorizationRequest');
    });
  });

  group('isAppleSignInSupported', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('is available on iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      expect(isAppleSignInSupported, isTrue);
    });

    test('is available on macOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      expect(isAppleSignInSupported, isTrue);
    });

    test('is not available on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      expect(isAppleSignInSupported, isFalse);
    });
  });
}
