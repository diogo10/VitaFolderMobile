enum InviteRelationship { self, spouse, child, parent, other }

sealed class InvitePeopleState {
  InvitePeopleState();
}

class InvitePeopleInitial extends InvitePeopleState {
  InvitePeopleInitial();
}

class InvitePeopleLoading extends InvitePeopleState {
  InvitePeopleLoading();
}

class InvitePeopleSuccess extends InvitePeopleState {
  InvitePeopleSuccess();
}

class InvitePeopleError extends InvitePeopleState {
  final String message;
  InvitePeopleError({required this.message});
}