import 'package:google_sign_in/google_sign_in.dart';
import 'package:house_mira_core/observability/app_logger.dart';

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
    AppLogger? logger,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
       _logger = logger ?? AppLogger();

  /// Web (server) OAuth client ID used as `serverClientId` during
  /// initialization. Required on Android so the ID token audience matches
  /// the client registered in the Supabase Google provider settings.
  static const String webClientId =
      '140355243144-q85g6alo5injsn28tiuotoqvmbckrql8'
      '.apps.googleusercontent.com';

  /// Scopes requested from Google before exchanging the ID token.
  static const List<String> scopes = <String>['email', 'profile'];

  /// Reported when the lightweight sign-in attempt fails and the interactive
  /// flow takes over.
  static const String _lightweightFailure =
      'Google lightweight sign-in failed, using interactive sign-in';

  final GoogleSignIn _googleSignIn;

  /// Web (server) OAuth client ID.
  final String? serverClientId;

  /// iOS OAuth client ID. `null` until an iOS OAuth client is registered for
  /// the app bundle (`com.housemira.app`) in Google Cloud; when `null`, the
  /// value from the platform configuration files is used, if present.
  ///
  /// An iOS OAuth client is now registered for `com.housemira.app`
  /// (`140355243144-jod5i62r34mvfelrd6pn580c50du58me`) and is picked up from
  /// `GoogleService-Info.plist` by `google_sign_in_ios`, so this stays `null`.
  final String? clientId;

  /// Structured logger. Warnings and errors are forwarded to Crashlytics so
  /// Google sign-in failures stay visible in production builds, where
  /// `debugPrint` output is discarded.
  final AppLogger _logger;

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _logger.debug(
      'initializing Google sign-in '
      '(clientId: ${clientId == null ? 'null (platform default)' : 'set'}, '
      'serverClientId: ${serverClientId == null ? 'null' : 'set'})',
      tag: 'auth',
    );
    try {
      await _googleSignIn.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
      );
    } on Object catch (e, stackTrace) {
      _logger.error(
        'Google sign-in initialization failed',
        tag: 'auth',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
    _initialized = true;
  }

  @override
  Future<GoogleAuthTokens?> signIn() async {
    await _ensureInitialized();

    final account = await _authenticate();
    if (account == null) return null;

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      _logger.error(
        'Google sign-in returned no ID token',
        tag: 'auth',
      );
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'No ID Token found.',
      );
    }

    final GoogleSignInClientAuthorization granted;
    try {
      final authorization = await account.authorizationClient
          .authorizationForScopes(GoogleSignInHandler.scopes);
      granted =
          authorization ??
          await account.authorizationClient.authorizeScopes(
            GoogleSignInHandler.scopes,
          );
    } on Object catch (e, stackTrace) {
      _logger.error(
        'Google scope authorization failed',
        tag: 'auth',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
    _logger.info('Google sign-in tokens retrieved', tag: 'auth');

    return GoogleAuthTokens(idToken: idToken, accessToken: granted.accessToken);
  }

  /// Signs in, preferring the lightweight (no-UI) flow and falling back to
  /// the interactive flow.
  ///
  /// The lightweight attempt is isolated from the interactive one: any
  /// failure while restoring a previous session is logged and the
  /// interactive flow takes over. Sharing a single `try` block would let a
  /// transient Credential Manager error abort the whole sign-in before the
  /// user ever sees the account picker.
  ///
  /// Returns `null` when the user cancels the interactive flow.
  Future<GoogleSignInAccount?> _authenticate() async {
    final restored = await _attemptLightweight();
    if (restored != null) return restored;

    try {
      return await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _logger.info('Google sign-in canceled by the user', tag: 'auth');
        return null;
      }
      rethrow;
    }
  }

  /// Attempts to restore a previous Google session without showing UI.
  ///
  /// Returns `null` when no session can be restored or when the attempt
  /// fails; failures are reported as warnings and never abort the sign-in.
  Future<GoogleSignInAccount?> _attemptLightweight() async {
    try {
      final lightweight = _googleSignIn.attemptLightweightAuthentication();
      if (lightweight == null) return null;

      final account = await lightweight;
      if (account != null) {
        _logger.info(
          'Google sign-in restored from a previous session',
          tag: 'auth',
        );
      }
      return account;
    } on GoogleSignInException catch (e, stackTrace) {
      _logger.warning(
        _lightweightFailure,
        tag: 'auth',
        context: {'code': e.code.name},
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    } on Object catch (e, stackTrace) {
      _logger.warning(
        _lightweightFailure,
        tag: 'auth',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await _googleSignIn.signOut();
    } on Object catch (e, stackTrace) {
      // Best-effort: Google sign-out must never block Supabase sign-out.
      _logger.warning(
        'Google sign-out failed',
        tag: 'auth',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
