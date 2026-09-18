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
}
