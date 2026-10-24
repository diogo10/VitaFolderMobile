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

enum InvitePeopleErrorCode { sendFailed }

class InvitePeopleError extends InvitePeopleState {
  InvitePeopleError(this.code);
  final InvitePeopleErrorCode code;
}
