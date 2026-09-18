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

  SignUpSuccess(this.user);
  final User user;
}

enum SignUpErrorCode { unexpected }

class SignUpError extends SignUpState {

  SignUpError({this.message, this.code});
  final String? message;
  final SignUpErrorCode? code;
}
