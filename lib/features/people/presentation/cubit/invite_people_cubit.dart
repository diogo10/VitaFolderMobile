import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/core/functions/edget_functions.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/invite_people_state.dart';

class InvitePeopleCubit extends Cubit<InvitePeopleState> {
  EdgetFunctions edgetFunctions;

  InvitePeopleCubit({required this.edgetFunctions})
    : super(InvitePeopleInitial());

  Future<void> sendInvite({
    required String email,
    required InviteRelationship relationship,
  }) async {
    emit(InvitePeopleLoading());
    try {
      final result = await edgetFunctions.sendEmail(
        to: email,
        subject: 'You have been invited as a ${relationship.name} for VitaFolder',
      );

      if (!result) {
        emit(InvitePeopleError(message: 'Failed to send invite email.'));
        return;
      }

      emit(InvitePeopleSuccess());
    } catch (e) {
      emit(InvitePeopleError(message: e.toString()));
    }
  }
}
