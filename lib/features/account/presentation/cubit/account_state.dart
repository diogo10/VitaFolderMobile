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
  AccountLoaded();
}

class NoAccount extends AccountState {
  NoAccount();
}
