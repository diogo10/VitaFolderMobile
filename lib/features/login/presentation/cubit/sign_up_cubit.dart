import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/features/login/presentation/cubit/sign_up_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit(this._authService) : super(SignUpInitial());
  final AuthService _authService;

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
        emit(SignUpSuccess(user));
      } else {
        emit(SignUpError(code: SignUpErrorCode.unexpected));
      }
    } on AuthException catch (e) {
      emit(SignUpError(message: e.message));
    } on Object catch (e) {
      emit(SignUpError(message: e.toString()));
    }
  }

  /// Signs in with Google via the native ID token exchange.
  ///
  /// Emits [SignUpLoading] first, then [SignUpSuccess] on success,
  /// [SignUpInitial] when the user cancels the Google flow (back to the
  /// form, nothing happened), or [SignUpError] with the failure message.
  Future<void> signInWithGoogle() async {
    emit(SignUpLoading());

    try {
      final user = await _authService.signInWithGoogle();

      if (user == null) {
        debugPrint('[SignUpCubit] Google sign-in canceled by the user.');
        emit(SignUpInitial());
        return;
      }

      debugPrint('[SignUpCubit] Google sign-in succeeded (${user.id}).');
      emit(SignUpSuccess(user));
    } on AuthException catch (e) {
      debugPrint('[SignUpCubit] Google sign-in failed: ${e.message}');
      emit(SignUpError(message: e.message));
    } on Object catch (e) {
      debugPrint('[SignUpCubit] Google sign-in error: $e');
      emit(SignUpError(message: e.toString()));
    }
  }
}
