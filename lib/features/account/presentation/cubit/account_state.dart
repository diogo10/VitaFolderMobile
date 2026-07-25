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

  AccountLoaded({required this.userName, required this.email, required this.familyCode});
}

class NoAccount extends AccountState {
  NoAccount();
}

class AccountLogoutSuccess extends AccountState {
  AccountLogoutSuccess();
}
