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

  AccountLoaded({
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
  PasswordResetError({required this.code});
  final PasswordResetErrorCode code;
}

class AccountLoginSuccess extends AccountState {
  AccountLoginSuccess();
}

class AccountDeleting extends AccountState {
  AccountDeleting();
}

class AccountDeletedSuccess extends AccountState {
  AccountDeletedSuccess();
}

enum AccountDeleteErrorCode { soleOwner, sendFailed }

class AccountDeleteFailed extends AccountState {
  AccountDeleteFailed({required this.code});
  final AccountDeleteErrorCode code;
}
