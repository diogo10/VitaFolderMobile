sealed class AccountState {
  AccountState();
}

class AccountInitial extends AccountState {
  AccountInitial();
}

class AccountLoading extends AccountState {
  AccountLoading();
}

class AccountLoaded extends AccountState {
  final String userName;
  final String email;
  final String familyCode;
  final String myRole;

  AccountLoaded({
    required this.userName,
    required this.email,
    required this.familyCode,
    required this.myRole,
  });
}

class NoAccount extends AccountState {
  NoAccount();
}

class AccountLogoutSuccess extends AccountState {
  AccountLogoutSuccess();
}

class LoginFailed extends AccountState {
  LoginFailed();
}

class PasswordResetSent extends AccountState {
  PasswordResetSent();
}

enum PasswordResetErrorCode { emptyEmail, sendFailed }

class PasswordResetError extends AccountState {
  final PasswordResetErrorCode code;
  PasswordResetError({required this.code});
}
