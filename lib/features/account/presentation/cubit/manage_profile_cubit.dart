import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/features/account/presentation/cubit/manage_profile_state.dart';

class ManageProfileCubit extends Cubit<ManageProfileState> {
  ManageProfileCubit({required AuthService authService})
    : _authService = authService,
      super(ManageProfileInitial());
  final AuthService _authService;

  Future<void> saveName(String name) async {
    emit(ManageProfileLoading());

    try {
      await _authService.updateName(name.trim());
      emit(ManageProfileSuccess());
    } on Object catch (e) {
      emit(ManageProfileError(message: e.toString()));
    }
  }
}
