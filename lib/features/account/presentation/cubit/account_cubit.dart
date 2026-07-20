import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  final AuthService _authService;

  AccountCubit([AuthService? authService])
      : _authService = authService ?? AuthService(),
        super(AccountInitial());

  Future<void> loadAccount() async {
    emit(AccountLoading());

    try {
      final user = _authService.currentUser;

      if (user != null) {
        emit(
          AccountLoaded(
            userName: user.userMetadata?['full_name']?.toString() ??
                user.email?.split('@').first ?? 'User',
            email: user.email ?? '',
          ),
        );
        return;
      }

      emit(NoAccount());
    } catch (_) {
      emit(NoAccount());
    }
  }

  Future<void> signIn(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      emit(NoAccount());
      return;
    }

    emit(AccountLoading());

    try {
      await _authService.signIn(
        email: email.trim(),
        password: password,
      );

      final user = _authService.currentUser;
      emit(
        AccountLoaded(
          userName: user?.userMetadata?['full_name']?.toString() ??
              email.trim().split('@').first,
          email: user?.email ?? email.trim(),
        ),
      );
    } catch (_) {
      emit(NoAccount());
    }
  }
}
