import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira/core/functions/edget_functions.dart';
import 'package:house_mira/features/people/presentation/cubit/invite_people_state.dart';

class InvitePeopleCubit extends Cubit<InvitePeopleState> {
  InvitePeopleCubit({required this.edgetFunctions})
    : super(InvitePeopleInitial());
  EdgetFunctions edgetFunctions;

  /// Sends a family invite email.
  ///
  /// [inviteCode]/[familyName] are optional: when provided they are embedded
  /// as the mobile App Link in the email body (see [EdgetFunctions]);
  /// otherwise a generic enroll prompt is sent.
  Future<void> sendInvite({
    required String email,
    required InviteRelationship relationship,
    required String subject,
    String? inviteCode,
    String? familyName,
  }) async {
    emit(InvitePeopleLoading());
    try {
      final result = await edgetFunctions.sendEmail(
        to: email,
        subject: subject,
        inviteCode: inviteCode,
        familyName: familyName,
      );

      if (!result) {
        emit(InvitePeopleError(code: InvitePeopleErrorCode.sendFailed));
        return;
      }

      emit(InvitePeopleSuccess());
    } on Object catch (e) {
      emit(InvitePeopleError(message: e.toString()));
    }
  }
}
