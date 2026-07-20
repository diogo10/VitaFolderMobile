import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/features/login/presentation/cubit/sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  final AuthService _authService;

  SignUpCubit(this._authService) : super(SignUpInitial());

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    emit(SignUpLoading());

    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
      );

      if (user != null) {
        emit(SignUpSuccess(user));
      } else {
        emit(SignUpError('An unexpected error occurred.'));
      }
    } on AuthException catch (e) {
      emit(SignUpError(e.message));
    } catch (e) {
      emit(SignUpError(e.toString()));
    }
  }
}
