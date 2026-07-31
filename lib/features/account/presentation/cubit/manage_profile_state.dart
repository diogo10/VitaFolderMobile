sealed class ManageProfileState {
  ManageProfileState();
}

class ManageProfileInitial extends ManageProfileState {
  ManageProfileInitial();
}

class ManageProfileLoading extends ManageProfileState {
  ManageProfileLoading();
}

class ManageProfileSuccess extends ManageProfileState {
  ManageProfileSuccess();
}

class ManageProfileError extends ManageProfileState {
  final String message;
  ManageProfileError({required this.message});
}
