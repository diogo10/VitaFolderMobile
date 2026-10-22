import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira_core/functions/edget_functions.dart';
import 'package:house_mira_people/presentation/cubit/invite_people_state.dart';

class InvitePeopleCubit extends Cubit<InvitePeopleState> {
  InvitePeopleCubit({required this.edgetFunctions})
    : super(InvitePeopleInitial());
  EdgetFunctions edgetFunctions;

  /// Emits [state] only while the cubit is still open.
  ///
  /// The invite screen owns this cubit through `BlocProvider(create:)`,
  /// so leaving the screen closes it while the invite email is still
  /// being sent. Emitting into a closed cubit throws `Bad state: Cannot
  /// emit new states after calling close` and crashes the app (FATAL
  /// Crashlytics issue `04df8a6a`).
  void _emitIfOpen(InvitePeopleState state) {
    if (isClosed) return;
    emit(state);
  }

  /// Sends a family invite email.
  ///
  /// [locale] selects the server-rendered email language (`en`/`pt`,
  /// English fallback). [inviterName]/[familyName]/[inviteCode]/[familyCode]
  /// are optional: when provided they personalize the email and its join CTA
  /// (see [EdgetFunctions]); otherwise a generic invite is sent.
  Future<void> sendInvite({
    required String email,
    required InviteRelationship relationship,
    required String locale,
    String? inviterName,
    String? familyName,
    String? inviteCode,
    String? familyCode,
  }) async {
    emit(InvitePeopleLoading());
    try {
      final result = await edgetFunctions.sendEmail(
        to: email,
        locale: locale,
        inviterName: inviterName,
        familyName: familyName,
        inviteCode: inviteCode,
        familyCode: familyCode,
      );

      if (!result) {
        _emitIfOpen(InvitePeopleError(code: InvitePeopleErrorCode.sendFailed));
        return;
      }

      _emitIfOpen(InvitePeopleSuccess());
    } on Object catch (e) {
      _emitIfOpen(InvitePeopleError(message: e.toString()));
    }
  }
}
