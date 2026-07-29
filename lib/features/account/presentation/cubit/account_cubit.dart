import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_state.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';

class AccountCubit extends Cubit<AccountState> {
  final AuthService _authService;
  final PeopleRepository _peopleRepository;

  AccountCubit({
    required AuthService authService,
    required PeopleRepository peopleRepository,
  })  : _authService = authService,
        _peopleRepository = peopleRepository,
        super(AccountInitial());

  Future<void> loadAccount() async {
    emit(AccountLoading());

    try {
      final user = _authService.currentUser;

      if (user != null) {
        final familyCode = await _getFamilyCodeForUser();
        emit(
          AccountLoaded(
            userName: user.userMetadata?['full_name']?.toString() ??
                user.email?.split('@').first ?? 'User',
            email: user.email ?? '',
            familyCode: familyCode,
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
      await _authService.signIn(
        email: email.trim(),
        password: password,
      );

      final user = _authService.currentUser;
       emit(AccountLoading());
      final familyCode = await _getFamilyCodeForUser();
      emit(
        AccountLoaded(
          userName: user?.userMetadata?['full_name']?.toString() ??
              email.trim().split('@').first,
          email: user?.email ?? email.trim(),
          familyCode: familyCode,
        ),
      );
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

  Future<String> _getFamilyCodeForUser() async {
    final result = await _peopleRepository.getFamily();
    return result.fold((_) => '', (family) => family.inviteCode);
  }
}
