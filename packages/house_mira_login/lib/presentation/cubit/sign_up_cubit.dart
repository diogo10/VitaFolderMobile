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
        emit(SignUpSuccess());
      } else {
        _logger.error('sign-up returned no user', tag: 'auth');
        emit(SignUpError(code: SignUpErrorCode.unexpected));
      }
    } on Object catch (e, stackTrace) {
      _logger.error(
        'sign-up failed',
        tag: 'auth',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
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
  Future<void> signInWithGoogle() async {
    emit(SignUpLoading());

    try {
      final user = await _authService.signInWithGoogle();

      if (user == null) {
        _logger.info('Google sign-in canceled by the user', tag: 'auth');
        emit(SignUpInitial());
        return;
      }

      _logger.info('Google sign-in succeeded', tag: 'auth');
      emit(SignUpSuccess());
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
      emit(
        SignUpError(
          code: code,
          message: _authService.authErrorMessage(e) ?? e.toString(),
        ),
      );
    }
  }
}
