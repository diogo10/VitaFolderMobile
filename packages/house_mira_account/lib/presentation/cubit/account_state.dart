sealed class AccountState {
  const AccountState();
}

class AccountInitial extends AccountState {
  const AccountInitial();
}

class AccountLoading extends AccountState {
  const AccountLoading();
}

class AccountLoaded extends AccountState {
  const AccountLoaded({
    required this.userName,
    required this.email,
    required this.familyCode,
    required this.myRole,
  });
  final String userName;
  final String email;
  final String familyCode;
  final String myRole;
}

class NoAccount extends AccountState {
  const NoAccount();
}

class AccountLogoutSuccess extends AccountState {
  const AccountLogoutSuccess();
}

enum AccountLoginErrorCode {
  invalidCredentials,
  googleSignInFailed,
  unexpected,
}

class LoginFailed extends AccountState {
  const LoginFailed({required this.code});
  final AccountLoginErrorCode code;
}

class PasswordResetSent extends AccountState {
  const PasswordResetSent();
}

enum PasswordResetErrorCode { emptyEmail, sendFailed }

class PasswordResetError extends AccountState {
  const PasswordResetError({required this.code});
  final PasswordResetErrorCode code;
}

class AccountLoginSuccess extends AccountState {
  const AccountLoginSuccess();
}

class AccountDeleting extends AccountState {
  const AccountDeleting();
}

class AccountDeletedSuccess extends AccountState {
  const AccountDeletedSuccess();
}

enum AccountDeleteErrorCode { soleOwner, sendFailed }

class AccountDeleteFailed extends AccountState {
  const AccountDeleteFailed({required this.code});
  final AccountDeleteErrorCode code;
}
