import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira_core/auth/auth_service.dart';
import 'package:house_mira_core/observability/app_logger.dart';
import 'package:house_mira_core/observability/crash_reporter.dart';
import 'package:house_mira_login/presentation/cubit/sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit(
    this._authService, {
    CrashReporter? crashReporter,
    AppLogger? logger,
  }) : _logger = logger ?? AppLogger(crashReporter: crashReporter),
       super(SignUpInitial());
  final AuthService _authService;
  final AppLogger _logger;

  /// Emits [state] only while the cubit is still open.
  ///
  /// Every sign-in flow awaits an external call (Supabase, Google, Apple),
  /// so the user can leave the screen — and the `BlocProvider` closes the
  /// cubit — while that call is still in flight. Emitting after `close()`
  /// throws `Bad state: Cannot emit new states after calling close` and
  /// took the app down (FATAL Crashlytics issue `04df8a6a`).
  void _emitIfOpen(SignUpState state) {
    if (isClosed) return;
    emit(state);
  }

  /// Signs up with email and password.
  ///
  /// Emits [SignUpLoading] first, then [SignUpSuccess] when the account is
  /// created, or [SignUpError] with [SignUpErrorCode.unexpected] when the
  /// request fails or returns no user.
  ///
  /// The request outlives the screen, so every emit that follows an
  /// `await` goes through [_emitIfOpen].
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    emit(SignUpLoading());

    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
      );

      if (user != null) {
        _emitIfOpen(SignUpSuccess());
      } else {
        _logger.error('sign-up returned no user', tag: 'auth');
        _emitIfOpen(SignUpError(code: SignUpErrorCode.unexpected));
      }
    } on Object catch (e, stackTrace) {
      _logger.error(
        'sign-up failed',
        tag: 'auth',
        error: e,
        stackTrace: stackTrace,
      );
      _emitIfOpen(
        SignUpError(
          code: SignUpErrorCode.unexpected,
          message: _authService.authErrorMessage(e) ?? e.toString(),
        ),
      );
    }
  }

  /// Signs in with Google via the native ID token exchange.
  ///
  /// Emits [SignUpLoading] first, then [SignUpSuccess] on success,
  /// [SignUpInitial] when the user cancels the Google flow (back to the
  /// form, nothing happened), or [SignUpError] with
  /// [SignUpErrorCode.googleSignInFailed] when the failure is a Google
  /// sign-in error (message carries the specific cause for logging, see
  /// [SignUpError.message]). Unexpected errors emit [SignUpError] with
  /// [SignUpErrorCode.unexpected] so the view shows actionable feedback.
  ///
  /// The native flow outlives the screen: the user can leave the sign-up
  /// screen while the Google sheet is up, which closes this cubit. Every
  /// emit that follows an `await` therefore goes through [_emitIfOpen].
  Future<void> signInWithGoogle() async {
    emit(SignUpLoading());

    try {
      final user = await _authService.signInWithGoogle();

      if (user == null) {
        _logger.info('Google sign-in canceled by the user', tag: 'auth');
        _emitIfOpen(SignUpInitial());
        return;
      }

      _logger.info('Google sign-in succeeded', tag: 'auth');
      _emitIfOpen(SignUpSuccess());
    } on Object catch (e, stackTrace) {
      final code = _authService.isAuthError(e)
          ? SignUpErrorCode.googleSignInFailed
          : SignUpErrorCode.unexpected;
      _logger.error(
        'Google sign-in failed',
        tag: 'auth',
        context: {'code': code.name},
        error: e,
        stackTrace: stackTrace,
      );
      _emitIfOpen(
        SignUpError(
          code: code,
          message: _authService.authErrorMessage(e) ?? e.toString(),
        ),
      );
    }
  }

  /// Signs in with Apple via the native identity token exchange.
  ///
  /// Emits [SignUpLoading] first, then [SignUpSuccess] on success,
  /// [SignUpInitial] when the user cancels the Apple flow (back to the
  /// form, nothing happened), or [SignUpError] with
  /// [SignUpErrorCode.appleSignInFailed] when the failure is an Apple
  /// sign-in error (message carries the specific cause for logging, see
  /// [SignUpError.message]). Unexpected errors emit [SignUpError] with
  /// [SignUpErrorCode.unexpected] so the view shows actionable feedback.
  ///
  /// The native flow outlives the screen, so every emit that follows an
  /// `await` goes through [_emitIfOpen].
  Future<void> signInWithApple() async {
    emit(SignUpLoading());

    try {
      final user = await _authService.signInWithApple();

      if (user == null) {
        _logger.info('Apple sign-in canceled by the user', tag: 'auth');
        _emitIfOpen(SignUpInitial());
        return;
      }

      _logger.info('Apple sign-in succeeded', tag: 'auth');
      _emitIfOpen(SignUpSuccess());
    } on Object catch (e, stackTrace) {
      final code = _authService.isAuthError(e)
          ? SignUpErrorCode.appleSignInFailed
          : SignUpErrorCode.unexpected;
      _logger.error(
        'Apple sign-in failed',
        tag: 'auth',
        context: {'code': code.name},
        error: e,
        stackTrace: stackTrace,
      );
      _emitIfOpen(
        SignUpError(
          code: code,
          message: _authService.authErrorMessage(e) ?? e.toString(),
        ),
      );
    }
  }
}
