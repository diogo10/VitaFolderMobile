import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:house_mira_core/observability/app_logger.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Whether native Sign in with Apple is available on this platform.
///
/// The native flow (Authentication Services) only exists on Apple
/// platforms. The plugin can also run a web flow on Android, but that
/// needs an Apple Services ID plus a redirect endpoint, so the Apple
/// button is only offered where the native flow works.
bool get isAppleSignInSupported =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// Apple authentication credentials retrieved from the native sign-in flow.
class AppleAuthCredentials {
  /// Creates the credentials used for the Supabase ID token exchange.
  const AppleAuthCredentials({
    required this.identityToken,
    required this.nonce,
    this.authorizationCode,
    this.givenName,
    this.familyName,
    this.email,
  });

  /// The Apple identity token (JWT) to exchange with Supabase via
  /// `signInWithIdToken`.
  final String identityToken;

  /// The raw nonce sent with the sign-in request.
  ///
  /// Apple receives the hashed nonce (embedded in the `nonce` claim of the
  /// identity token) and Supabase hashes the raw nonce again to compare
  /// both, which mitigates replay attacks.
  final String nonce;

  /// The one-time authorization code returned by Apple.
  ///
  /// Kept for diagnostics only: the client exchanges the identity token,
  /// never the code.
  final String? authorizationCode;

  /// The given name, only provided on the first authorization.
  final String? givenName;

  /// The family name, only provided on the first authorization.
  final String? familyName;

  /// The email, only provided on the first authorization.
  final String? email;

  /// The full name Apple provided on the first authorization.
  ///
  /// `null` when Apple did not return a name (every sign-in after the
  /// first one), because the identity token never carries it.
  String? get fullName {
    final parts = <String>[
      if (givenName != null && givenName!.isNotEmpty) givenName!,
      if (familyName != null && familyName!.isNotEmpty) familyName!,
    ];
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }
}

/// The reason an Apple sign-in attempt failed.
enum AppleSignInErrorCode {
  /// The device or OS version does not support Sign in with Apple.
  notSupported,

  /// Apple did not return an identity token.
  missingIdentityToken,

  /// The sign-in attempt failed for any other reason.
  failed,
}

/// Thrown when the native Apple sign-in flow fails.
///
/// The [detail] is kept for diagnostics only: the UI always shows a
/// generic, localized message.
class AppleSignInException implements Exception {
  /// Creates an Apple sign-in failure.
  const AppleSignInException(this.code, {this.detail});

  /// The machine-readable reason of the failure.
  final AppleSignInErrorCode code;

  /// The underlying platform detail, for logs only.
  final String? detail;

  @override
  String toString() =>
      'AppleSignInException(${code.name}${detail == null ? '' : ': $detail'})';
}

/// Signature of the credential provider used by [AppleSignInHandler].
///
/// Injecting the provider keeps the handler unit-testable: the plugin
/// entry point talks to a platform channel that cannot run in tests.
typedef AppleIdCredentialProvider =
    Future<AuthorizationCredentialAppleID> Function({
      required List<AppleIDAuthorizationScopes> scopes,
      String? nonce,
    });

/// Abstraction over the `sign_in_with_apple` package.
///
/// Lets the authentication service retrieve the Apple identity token
/// without depending on the plugin directly, which keeps the
/// authentication flow unit-testable.
abstract class IAppleSignInHandler {
  /// Runs the native Apple sign-in flow and returns the credentials.
  ///
  /// Returns `null` when the user cancels the flow.
  Future<AppleAuthCredentials?> signIn();

  /// Signs out from Apple. Best-effort: never throws.
  Future<void> signOut();
}

/// Production [IAppleSignInHandler] backed by `sign_in_with_apple`.
class AppleSignInHandler implements IAppleSignInHandler {
  /// Creates a handler that requests the Apple credential on first use.
  AppleSignInHandler({
    AppleIdCredentialProvider? credentialProvider,
    AppLogger? logger,
  }) : _credentialProvider = credentialProvider ?? _requestAppleIdCredential,
       _logger = logger ?? AppLogger();

  /// Scopes requested from Apple before the token exchange.
  ///
  /// The name scope is required to show the user's name: Apple only
  /// returns it on the very first authorization.
  static const List<AppleIDAuthorizationScopes> scopes =
      <AppleIDAuthorizationScopes>[
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ];

  final AppleIdCredentialProvider _credentialProvider;

  /// Structured logger. Errors are forwarded to Crashlytics so Apple
  /// sign-in failures stay visible in production builds, where
  /// `debugPrint` output is discarded.
  final AppLogger _logger;

  /// Requests the credential from the plugin.
  static Future<AuthorizationCredentialAppleID> _requestAppleIdCredential({
    required List<AppleIDAuthorizationScopes> scopes,
    String? nonce,
  }) {
    return SignInWithApple.getAppleIDCredential(scopes: scopes, nonce: nonce);
  }

  @override
  Future<AppleAuthCredentials?> signIn() async {
    // A fresh nonce per attempt: Apple embeds the hashed nonce in the
    // identity token and Supabase compares it with the hashed raw nonce,
    // so a replayed token is rejected.
    final rawNonce = generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final AuthorizationCredentialAppleID credential;
    try {
      credential = await _credentialProvider(
        scopes: scopes,
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e, stackTrace) {
      if (e.code == AuthorizationErrorCode.canceled) {
        _logger.info('Apple sign-in canceled by the user', tag: 'auth');
        return null;
      }
      _logger.error(
        'Apple sign-in failed',
        tag: 'auth',
        context: {'code': e.code.name},
        error: e,
        stackTrace: stackTrace,
      );
      throw AppleSignInException(
        AppleSignInErrorCode.failed,
        detail: e.message,
      );
    } on SignInWithAppleNotSupportedException catch (e, stackTrace) {
      _logger.error(
        'Apple sign-in is not supported on this device',
        tag: 'auth',
        error: e,
        stackTrace: stackTrace,
      );
      throw AppleSignInException(
        AppleSignInErrorCode.notSupported,
        detail: e.message,
      );
    } on Object catch (e, stackTrace) {
      _logger.error(
        'Apple sign-in failed',
        tag: 'auth',
        error: e,
        stackTrace: stackTrace,
      );
      throw AppleSignInException(
        AppleSignInErrorCode.failed,
        detail: e.toString(),
      );
    }

    final identityToken = credential.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      _logger.error(
        'Apple sign-in returned no identity token',
        tag: 'auth',
      );
      throw const AppleSignInException(
        AppleSignInErrorCode.missingIdentityToken,
      );
    }

    _logger.info('Apple sign-in credential retrieved', tag: 'auth');

    return AppleAuthCredentials(
      identityToken: identityToken,
      nonce: rawNonce,
      authorizationCode: credential.authorizationCode,
      givenName: credential.givenName,
      familyName: credential.familyName,
      email: credential.email,
    );
  }

  @override
  Future<void> signOut() async {
    // Apple exposes no sign-out API: the credential stays in the keychain
    // and the Supabase session is the single source of truth for the
    // session. Nothing to revoke here.
    _logger.debug(
      'Apple sign-out has nothing to revoke (no native API)',
      tag: 'auth',
    );
  }
}
