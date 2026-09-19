import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/features/account/presentation/cubit/account_state.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountCubit extends Cubit<AccountState> {
  AccountCubit({
    required AuthService authService,
    required PeopleRepository peopleRepository,
    Stream<AuthState>? authStateStream,
  }) : _authService = authService,
       _peopleRepository = peopleRepository,
       super(AccountInitial()) {
    try {
      _authSubscription = (authStateStream ?? _authService.authStateChanges)
          .listen(_onAuthState);
    } on Object catch (_) {
      // Best-effort: account still loads on demand via loadAccount().
    }
  }
  final AuthService _authService;
  final PeopleRepository _peopleRepository;
  StreamSubscription<AuthState>? _authSubscription;

  /// Keeps the account tab in sync with the session.
  ///
  /// The account branch stays alive in the indexed-stack shell, so a
  /// registration from `/sign-up` (which navigates to `/home`) would
  /// otherwise leave a stale `NoAccount` state behind. Reloading on
  /// sign-in and clearing on sign-out fixes that without the views
  /// having to coordinate.
  void _onAuthState(AuthState state) {
    if (isClosed) return;
    if (state.session != null) {
      unawaited(loadAccount());
    } else {
      emit(NoAccount());
    }
  }

  @override
  Future<void> close() {
    unawaited(_authSubscription?.cancel());
    return super.close();
  }

  Future<void> loadAccount() async {
    emit(AccountLoading());

    try {
      final user = await _authService.getAsPersonEntity();

      if (user != null) {
        final familyCode = await _getFamilyCodeForUser();
        final myRole = await _peopleRepository.getMyFamilyRole();
        emit(
          AccountLoaded(
            userName: user.name ?? '------',
            email: user.email ?? '',
            familyCode: familyCode,
            myRole: myRole.isEmpty ? '' : myRole.first,
          ),
        );

        return;
      }

      emit(NoAccount());
    } on Object catch (_) {
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

  /// Signs in with Google via the native ID token exchange.
  ///
  /// Delegates to [AuthService.signInWithGoogle]. Emits [NoAccount] when
  /// the user cancels the Google flow (nothing happened, back to the
  /// form), [LoginFailed] when the exchange fails, and loads the account
  /// on success like [signIn] does.
  Future<void> signInWithGoogle() async {
    emit(AccountLoading());

    try {
      final user = await _authService.signInWithGoogle();

      if (user == null) {
        debugPrint('[AccountCubit] Google sign-in canceled by the user.');
        emit(NoAccount());
        return;
      }

      debugPrint('[AccountCubit] Google sign-in succeeded (${user.id}).');
      emit(AccountLoginSuccess());
      await loadAccount();
    } on AuthException catch (e) {
      debugPrint('[AccountCubit] Google sign-in failed: ${e.message}');
      emit(LoginFailed());
    } on Object catch (e) {
      debugPrint('[AccountCubit] Google sign-in error: $e');
      emit(NoAccount());
    }
  }

  Future<void> signOut() async {
    emit(AccountLoading());

    try {
      await _authService.signOut();
      emit(AccountLogoutSuccess());
    } on Object catch (_) {
      emit(NoAccount());
    }
  }

  /// Permanently deletes the current user's account.
  ///
  /// Delegates the server-side deletion to [AuthService.deleteAccount]
  /// (edge function + cascade), then signs out locally so the router
  /// reacts to the auth state change like a regular sign-out.
  /// Emits [AccountDeleteFailed] with `soleOwner` when the user is the
  /// last remaining member of an owned family — nothing is deleted and
  /// the UI should point them at Family Settings. After a failure the
  /// account is reloaded so the user lands back on their settings.
  Future<void> deleteAccount() async {
    emit(AccountDeleting());

    try {
      await _authService.deleteAccount();
      await _authService.signOut();
      emit(AccountDeletedSuccess());
    } on SoleOwnerException {
      emit(AccountDeleteFailed(code: AccountDeleteErrorCode.soleOwner));
      await loadAccount();
    } on Object catch (_) {
      emit(AccountDeleteFailed(code: AccountDeleteErrorCode.sendFailed));
      await loadAccount();
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
    } on Object catch (_) {
      emit(PasswordResetError(code: PasswordResetErrorCode.sendFailed));
    }
  }

  Future<String> _getFamilyCodeForUser() async {
    final result = await _peopleRepository.getMyFamily();
    return result.fold((_) => '', (family) => family.inviteCode);
  }
}
