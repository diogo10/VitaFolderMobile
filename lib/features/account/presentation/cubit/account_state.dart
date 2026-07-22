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

  AccountLoaded({required this.userName, required this.email});
}

class NoAccount extends AccountState {
  NoAccount();
}

class AccountLogoutSuccess extends AccountState {
  AccountLogoutSuccess();
}
