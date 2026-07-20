import 'package:supabase_flutter/supabase_flutter.dart';

sealed class SignUpState {
  SignUpState();
}

class SignUpInitial extends SignUpState {
  SignUpInitial();
}

class SignUpLoading extends SignUpState {
  SignUpLoading();
}

class SignUpSuccess extends SignUpState {
  final User user;

  SignUpSuccess(this.user);
}

class SignUpError extends SignUpState {
  final String message;

  SignUpError(this.message);
}
