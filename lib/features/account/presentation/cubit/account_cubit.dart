import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/features/account/presentation/cubit/account_state.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';

class AccountCubit extends Cubit<AccountState> {
  final AuthService _authService;
  final PeopleRepository _peopleRepository;

  AccountCubit({
    required AuthService authService,
    required PeopleRepository peopleRepository,
  }) : _authService = authService,
       _peopleRepository = peopleRepository,
       super(AccountInitial());

  Future<void> loadAccount() async {
    emit(AccountLoading());

    try {
      final user = await _authService.getAsPersonEntity();

      if (user != null) {
        final familyCode = await _getFamilyCodeForUser();
        final myRole = await _peopleRepository.getMyFamilyRole();
        emit(
          AccountLoaded(
            userName: user.name ?? "------",
            email: user.email ?? '',
            familyCode: familyCode,
            myRole: myRole.first,
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

    try {
      await _authService.signIn(email: email.trim(), password: password);

      final user = _authService.currentUser;
      if (user != null) {
        emit(AccountLoginSuccess());
        await loadAccount();
      } else {
        emit(LoginFailed());
      }
    } on Exception catch (e, _) {
      if (e is AuthApiException) {
        emit(LoginFailed());
      } else {
        emit(NoAccount());
      }
    }
  }

  Future<void> signOut() async {
    emit(AccountLoading());

    try {
      await _authService.signOut();
      emit(AccountLogoutSuccess());
    } catch (_) {
      emit(NoAccount());
    }
  }

  Future<void> forgotPassword(String email) async {
    if (email.trim().isEmpty) {
      emit(PasswordResetError(code: PasswordResetErrorCode.emptyEmail));
      return;
    }

    try {
      await _authService.resetPassword(email);
      emit(PasswordResetSent());
    } catch (_) {
      emit(PasswordResetError(code: PasswordResetErrorCode.sendFailed));
    }
  }

  Future<String> _getFamilyCodeForUser() async {
    final result = await _peopleRepository.getMyFamily();
    return result.fold((_) => '', (family) => family.inviteCode);
  }
}
