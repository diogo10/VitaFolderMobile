import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/observability/app_logger.dart';
import 'package:house_mira/core/observability/crash_reporter.dart';
import 'package:house_mira/core/subscriptions/subscription_service.dart';
import 'package:house_mira/features/account/presentation/cubit/account_state.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';

class AccountCubit extends Cubit<AccountState> {
  AccountCubit({
    required AuthService authService,
    required PeopleRepository peopleRepository,
    Stream<bool>? authSignedInStream,
    CrashReporter? crashReporter,
    AppLogger? logger,
    SubscriptionService? subscriptionService,
  }) : _authService = authService,
       _peopleRepository = peopleRepository,
       _logger = logger ?? AppLogger(crashReporter: crashReporter),
       _subscriptionService = subscriptionService,
       super(const AccountInitial()) {
    try {
      _authSubscription =
          (authSignedInStream ?? _authService.authSignedInChanges).listen(
            _onSignedInChanged,
          );
    } on Object catch (_) {
      // Best-effort: account still loads on demand via loadAccount().
    }
  }
  final AuthService _authService;
  final PeopleRepository _peopleRepository;
  final AppLogger _logger;
  StreamSubscription<bool>? _authSubscription;

  /// Drops the cached entitlement on sign-out so the next account never
  /// reads the previous user's billing status. Optional so tests can omit
  /// billing; the entitlement cache is additionally keyed by user id.
  final SubscriptionService? _subscriptionService;

  /// Keeps the account tab in sync with the session.
  ///
  /// The account branch stays alive in the indexed-stack shell, so a
  /// registration from `/sign-up` (which navigates to `/home`) would
  /// otherwise leave a stale `NoAccount` state behind. Reloading on
  /// sign-in and clearing on sign-out fixes that without the views
  /// having to coordinate.
  void _onSignedInChanged(bool signedIn) {
    if (isClosed) return;
    if (signedIn) {
      unawaited(loadAccount());
    } else {
      emit(const NoAccount());
    }
  }

  @override
  Future<void> close() {
    unawaited(_authSubscription?.cancel());
    return super.close();
  }

  Future<void> loadAccount() async {
    emit(const AccountLoading());

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

      emit(const NoAccount());
    } on Object catch (e, stackTrace) {
      _logger.warning(
        'load account failed',
        tag: 'account',
        error: e,
        stackTrace: stackTrace,
      );
      emit(const NoAccount());
    }
  }

  /// Signs in with email and password.
  ///
  /// Blank credentials are a validation no-op ([NoAccount], the API is
  /// never called). Every thrown failure maps to [LoginFailed] —
  /// [AccountLoginErrorCode.invalidCredentials] for Supabase
  /// invalid-credentials rejections, [AccountLoginErrorCode.unexpected]
  /// otherwise — so the view always shows actionable feedback instead of
  /// silently returning to the form.
  Future<void> signIn(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      emit(const NoAccount());
      return;
    }

    try {
      await _authService.signIn(email: email.trim(), password: password);

      final user = _authService.currentUser;
      if (user != null) {
        emit(const AccountLoginSuccess());
        await loadAccount();
      } else {
        _logger.warning('sign-in returned no user', tag: 'account');
        emit(const LoginFailed(code: AccountLoginErrorCode.unexpected));
      }
    } on Object catch (e, stackTrace) {
      final code = _authService.isInvalidCredentialsError(e)
          ? AccountLoginErrorCode.invalidCredentials
          : AccountLoginErrorCode.unexpected;
      _logger.error(
        'sign-in failed',
        tag: 'account',
        context: {'code': code.name},
        error: e,
        stackTrace: stackTrace,
      );
      emit(LoginFailed(code: code));
    }
  }

  /// Signs in with Google via the native ID token exchange.
  ///
  /// Delegates to [AuthService.signInWithGoogle]. Emits [NoAccount] when
  /// the user cancels the Google flow (nothing happened, back to the
  /// form), [LoginFailed] with a typed [AccountLoginErrorCode] when the
  /// exchange fails, and loads the account on success like [signIn] does.
  /// Unexpected errors also emit [LoginFailed] so the view can show
  /// actionable feedback instead of silently returning to the form.
  Future<void> signInWithGoogle() async {
    emit(const AccountLoading());

    try {
      final user = await _authService.signInWithGoogle();

      if (user == null) {
        _logger.info('Google sign-in canceled by the user', tag: 'account');
        emit(const NoAccount());
        return;
      }

      _logger.info('Google sign-in succeeded', tag: 'account');
      emit(const AccountLoginSuccess());
      await loadAccount();
    } on Object catch (e, stackTrace) {
      final code = _authService.isAuthError(e)
          ? AccountLoginErrorCode.googleSignInFailed
          : AccountLoginErrorCode.unexpected;
      _logger.error(
        'Google sign-in failed',
        tag: 'account',
        context: {'code': code.name},
        error: e,
        stackTrace: stackTrace,
      );
      emit(LoginFailed(code: code));
    }
  }

  Future<void> signOut() async {
    emit(const AccountLoading());

    try {
      await _authService.signOut();
      _subscriptionService?.invalidateProCache();
      emit(const AccountLogoutSuccess());
    } on Object catch (e, stackTrace) {
      _logger.warning(
        'sign-out failed',
        tag: 'account',
        error: e,
        stackTrace: stackTrace,
      );
      emit(const NoAccount());
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
    emit(const AccountDeleting());

    try {
      await _authService.deleteAccount();
      await _authService.signOut();
      _subscriptionService?.invalidateProCache();
      emit(const AccountDeletedSuccess());
    } on SoleOwnerException {
      emit(const AccountDeleteFailed(code: AccountDeleteErrorCode.soleOwner));
      await loadAccount();
    } on Object catch (e, stackTrace) {
      _logger.error(
        'delete account failed',
        tag: 'account',
        error: e,
        stackTrace: stackTrace,
      );
      emit(const AccountDeleteFailed(code: AccountDeleteErrorCode.sendFailed));
      await loadAccount();
    }
  }

  Future<void> forgotPassword(String email) async {
    if (email.trim().isEmpty) {
      emit(const PasswordResetError(code: PasswordResetErrorCode.emptyEmail));
      return;
    }

    try {
      await _authService.resetPassword(email);
      emit(const PasswordResetSent());
    } on Object catch (e, stackTrace) {
      _logger.error(
        'password reset failed',
        tag: 'account',
        error: e,
        stackTrace: stackTrace,
      );
      emit(const PasswordResetError(code: PasswordResetErrorCode.sendFailed));
    }
  }

  Future<String> _getFamilyCodeForUser() async {
    final result = await _peopleRepository.getMyFamily();
    return result.fold((_) => '', (family) => family.inviteCode);
  }
}
