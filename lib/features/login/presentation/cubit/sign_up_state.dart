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
  SignUpSuccess();
}

enum SignUpErrorCode { unexpected, googleSignInFailed }

class SignUpError extends SignUpState {
  SignUpError({required this.code, this.message});
  final SignUpErrorCode code;

  /// Raw auth failure detail, captured for logging/diagnostics only.
  ///
  /// The sign-up view deliberately shows only the generic localized message
  /// for [code] and never renders this string, so users get actionable,
  /// translated feedback while the specific cause stays in the logs.
  final String? message;
}
