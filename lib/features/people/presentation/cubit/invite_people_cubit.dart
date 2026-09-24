import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira/core/functions/edget_functions.dart';
import 'package:house_mira/features/people/presentation/cubit/invite_people_state.dart';

class InvitePeopleCubit extends Cubit<InvitePeopleState> {
  InvitePeopleCubit({required this.edgetFunctions})
    : super(InvitePeopleInitial());
  EdgetFunctions edgetFunctions;

  /// Sends a family invite email.
  ///
  /// [locale] selects the server-rendered email language (`en`/`pt`,
  /// English fallback). [inviterName]/[familyName]/[inviteCode] are
  /// optional: when provided they personalize the email and its join CTA
  /// (see [EdgetFunctions]); otherwise a generic invite is sent.
  Future<void> sendInvite({
    required String email,
    required InviteRelationship relationship,
    required String locale,
    String? inviterName,
    String? familyName,
    String? inviteCode,
  }) async {
    emit(InvitePeopleLoading());
    try {
      final result = await edgetFunctions.sendEmail(
        to: email,
        locale: locale,
        inviterName: inviterName,
        familyName: familyName,
        inviteCode: inviteCode,
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
