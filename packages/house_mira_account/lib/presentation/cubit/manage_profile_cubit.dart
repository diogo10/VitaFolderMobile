import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira_core/auth/auth_service.dart';
import 'package:house_mira_account/presentation/cubit/manage_profile_state.dart';

class ManageProfileCubit extends Cubit<ManageProfileState> {
  ManageProfileCubit({required AuthService authService})
    : _authService = authService,
      super(ManageProfileInitial());
  final AuthService _authService;

  /// Emits [state] only while the cubit is still open.
  ///
  /// The screen owns this cubit through `BlocProvider(create:)`, so
  /// leaving it closes the cubit while the profile update is still in
  /// flight. Emitting into a closed cubit throws `Bad state: Cannot emit
  /// new states after calling close` and crashes the app (FATAL
  /// Crashlytics issue `04df8a6a`).
  void _emitIfOpen(ManageProfileState state) {
    if (isClosed) return;
    emit(state);
  }

  Future<void> saveName(String name) async {
    emit(ManageProfileLoading());

    try {
      await _authService.updateName(name.trim());
      _emitIfOpen(ManageProfileSuccess());
    } on Object catch (e) {
      _emitIfOpen(ManageProfileError(message: e.toString()));
    }
  }

  /// Returns the current display name for pre-filling the manage-profile
  /// form when the route was reached without a coordinator snapshot (e.g.
  /// deep-link entry while the account tab is unbuilt). Best-effort:
  /// `null` keeps the field empty but editable.
  Future<String?> currentName() => _authService.getProfileName();
}
