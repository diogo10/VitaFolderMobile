import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google authentication tokens retrieved from the native sign-in flow.
class GoogleAuthTokens {
  /// Creates the Google tokens used for the Supabase ID token exchange.
  const GoogleAuthTokens({required this.idToken, this.accessToken});

  /// The Google ID token to exchange with Supabase via `signInWithIdToken`.
  final String idToken;

  /// The Google access token, when authorization scopes were granted.
  final String? accessToken;
}

/// Abstraction over the `google_sign_in` package.
///
/// Lets the authentication service retrieve Google tokens without depending
/// on the `GoogleSignIn` singleton directly, which keeps the authentication
/// flow unit-testable.
abstract class IGoogleSignInHandler {
  /// Runs the native Google sign-in flow and returns the resulting tokens.
  ///
  /// Returns `null` when the user cancels the flow.
  Future<GoogleAuthTokens?> signIn();

  /// Signs out from Google. Best-effort: never throws.
  Future<void> signOut();
}

/// Production [IGoogleSignInHandler] backed by `google_sign_in` v7.
class GoogleSignInHandler implements IGoogleSignInHandler {
  /// Creates a handler that initializes `google_sign_in` on first use.
  GoogleSignInHandler({
    GoogleSignIn? googleSignIn,
    this.serverClientId = GoogleSignInHandler.webClientId,
    this.clientId,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  /// Web (server) OAuth client ID used as `serverClientId` during
  /// initialization. Required on Android so the ID token audience matches
  /// the client registered in the Supabase Google provider settings.
  static const String webClientId =
      '140355243144-q85g6alo5injsn28tiuotoqvmbckrql8'
      '.apps.googleusercontent.com';

  /// Scopes requested from Google before exchanging the ID token.
  static const List<String> scopes = <String>['email', 'profile'];

  final GoogleSignIn _googleSignIn;

  /// Web (server) OAuth client ID.
  final String? serverClientId;

  /// iOS OAuth client ID. `null` until an iOS OAuth client is registered for
  /// the app bundle (`com.housemira.app`) in Google Cloud; when `null`, the
  /// value from the platform configuration files is used, if present.
  ///
  // TODO(diogohenrique): register an iOS OAuth client and pass its ID here
  /// (and add the corresponding `REVERSED_CLIENT_ID` URL scheme to
  /// `ios/Runner/Info.plist`).
  final String? clientId;

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    debugPrint(
      '[GoogleSignIn] initialize '
      '(clientId: ${clientId == null ? 'null (platform default)' : 'set'}, '
      'serverClientId: ${serverClientId == null ? 'null' : 'set'})',
    );
    try {
      await _googleSignIn.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
      );
    } on Object catch (e) {
      debugPrint('[GoogleSignIn] initialize failed: $e');
      rethrow;
    }
    _initialized = true;
  }

  @override
  Future<GoogleAuthTokens?> signIn() async {
    await _ensureInitialized();

    GoogleSignInAccount? account;
    try {
      final lightweight = _googleSignIn.attemptLightweightAuthentication();
      if (lightweight != null) {
        account = await lightweight;
        debugPrint('[GoogleSignIn] lightweight authentication restored.');
      }
      account ??= await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      debugPrint(
        '[GoogleSignIn] authenticate failed '
        '(code: ${e.code.name}, description: ${e.description})',
      );
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      debugPrint('[GoogleSignIn] no ID token returned for ${account.email}.');
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'No ID Token found.',
      );
    }

    GoogleSignInClientAuthorization? authorization;
    try {
      authorization = await account.authorizationClient.authorizationForScopes(
        GoogleSignInHandler.scopes,
      );
    } on Object catch (e) {
      debugPrint('[GoogleSignIn] authorizationForScopes failed: $e');
      rethrow;
    }

    GoogleSignInClientAuthorization granted;
    try {
      granted =
          authorization ??
          await account.authorizationClient.authorizeScopes(
            GoogleSignInHandler.scopes,
          );
    } on Object catch (e) {
      debugPrint('[GoogleSignIn] authorizeScopes failed: $e');
      rethrow;
    }
    debugPrint('[GoogleSignIn] tokens retrieved for ${account.email}.');

    return GoogleAuthTokens(idToken: idToken, accessToken: granted.accessToken);
  }

  @override
  Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await _googleSignIn.signOut();
    } on Object catch (_) {
      // Best-effort: Google sign-out must never block Supabase sign-out.
    }
  }
}
