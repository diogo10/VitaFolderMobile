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
  ManageProfileError({required this.message});
  final String message;
}
