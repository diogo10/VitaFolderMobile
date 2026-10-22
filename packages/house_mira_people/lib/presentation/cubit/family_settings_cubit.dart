import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira_core/auth/auth_service.dart';
import 'package:house_mira_people/domain/entities/person_entity.dart';
import 'package:house_mira_people/domain/usecase/delete_family_usecase.dart';
import 'package:house_mira_people/domain/usecase/get_my_family_id_usecase.dart';
import 'package:house_mira_people/domain/usecase/get_people_usecase.dart';
import 'package:house_mira_people/domain/usecase/remove_member_usecase.dart';
import 'package:house_mira_people/domain/usecase/update_family_name_usecase.dart';
import 'package:house_mira_people/presentation/cubit/family_settings_state.dart';

class FamilySettingsCubit extends Cubit<FamilySettingsState> {
  FamilySettingsCubit({
    required GetPeopleUsecase getPeopleUsecase,
    required GetMyFamilyIdUsecase getMyFamilyIdUsecase,
    required UpdateFamilyNameUsecase updateFamilyNameUsecase,
    required RemoveMemberUsecase removeMemberUsecase,
    required DeleteFamilyUsecase deleteFamilyUsecase,
    required AuthService authService,
  }) : _getPeopleUsecase = getPeopleUsecase,
       _getMyFamilyIdUsecase = getMyFamilyIdUsecase,
       _updateFamilyNameUsecase = updateFamilyNameUsecase,
       _removeMemberUsecase = removeMemberUsecase,
       _deleteFamilyUsecase = deleteFamilyUsecase,
       _authService = authService,
       super(const FamilySettingsInitial());
  final GetPeopleUsecase _getPeopleUsecase;
  final GetMyFamilyIdUsecase _getMyFamilyIdUsecase;
  final UpdateFamilyNameUsecase _updateFamilyNameUsecase;
  final RemoveMemberUsecase _removeMemberUsecase;
  final DeleteFamilyUsecase _deleteFamilyUsecase;
  final AuthService _authService;

  /// Emits [state] only while the cubit is still open.
  ///
  /// The screen owns this cubit through `BlocProvider(create:)`, so
  /// leaving it closes the cubit while a settings request is still in
  /// flight. Emitting into a closed cubit throws `Bad state: Cannot emit
  /// new states after calling close` and crashes the app (FATAL
  /// Crashlytics issue `04df8a6a`).
  void _emitIfOpen(FamilySettingsState state) {
    if (isClosed) return;
    emit(state);
  }

  Future<void> loadSettings() async {
    emit(const FamilySettingsLoading());

    try {
      final result = await _getPeopleUsecase();

      result.fold(
        (error) => _emitIfOpen(
          const FamilySettingsError(code: FamilySettingsErrorCode.loadFailed),
        ),
        (peopleData) {
          final currentUserId = _authService.currentUserId ?? '';

          // Admins manage the circle; every member may still open settings
          // to leave it. The view gates admin-only actions on [isAdmin];
          // the queue/save/delete guards below re-check it so a crafted
          // call cannot bypass the UI. Supabase RLS is the backend
          // enforcement point (see
          // supabase/migrations/20261007120000_family_admin_rls.sql):
          // families update/delete is admin/owner-only and
          // family_memberships delete is self-or-admin-only, so member
          // self-leave keeps working.
          final currentUserRole = peopleData.people
              .firstWhere(
                (p) => p.id == currentUserId,
                orElse: PersonEntity.new,
              )
              .role;
          final role = currentUserRole?.toLowerCase();
          final isAdmin = role == 'admin' || role == 'owner';

          _emitIfOpen(
            FamilySettingsLoaded(
              familyName: peopleData.family.name,
              members: peopleData.people,
              currentUserId: currentUserId,
              isAdmin: isAdmin,
            ),
          );
        },
      );
    } on Object catch (_) {
      _emitIfOpen(
        const FamilySettingsError(code: FamilySettingsErrorCode.loadFailed),
      );
    }
  }

  /// Fail-closed admin check. Cubit-level defense-in-depth: the view hides
  /// admin actions and Supabase RLS enforces them backend-side (see
  /// supabase/migrations/20261007120000_family_admin_rls.sql); this keeps
  /// a non-admin programmatic call from reaching the repository.
  ///
  /// Non-destructive: returns false without emitting so a denied call
  /// preserves the loaded settings instead of replacing them with an
  /// error state.
  bool _requireAdmin(FamilySettingsLoaded current) {
    return current.isAdmin;
  }

  void queueFamilyNameChange(String name) {
    if (state is FamilySettingsLoaded) {
      final current = state as FamilySettingsLoaded;
      if (!_requireAdmin(current)) return;
      final trimmed = name.trim();
      // Reject empty names: never queue (or send) a blank family name.
      if (trimmed.isEmpty) return;
      emit(current.copyWith(pendingFamilyName: trimmed));
    }
  }

  void queueMemberRemoval(String memberId) {
    if (state is FamilySettingsLoaded) {
      final current = state as FamilySettingsLoaded;
      if (!_requireAdmin(current)) return;
      final newRemovals = Set<String>.from(current.pendingRemovals)
        ..add(memberId);
      emit(current.copyWith(pendingRemovals: newRemovals));
    }
  }

  void cancelMemberRemoval(String memberId) {
    if (state is FamilySettingsLoaded) {
      final current = state as FamilySettingsLoaded;
      if (!_requireAdmin(current)) return;
      final newRemovals = Set<String>.from(current.pendingRemovals)
        ..remove(memberId);
      emit(current.copyWith(pendingRemovals: newRemovals));
    }
  }

  Future<void> saveChanges() async {
    if (state is! FamilySettingsLoaded) return;

    final current = state as FamilySettingsLoaded;
    if (!_requireAdmin(current)) return;
    // Defense-in-depth: queueFamilyNameChange already rejects blank names,
    // but never send an empty name to the backend from a crafted state.
    final trimmedPending = current.pendingFamilyName?.trim();
    final hasNameChange =
        trimmedPending != null &&
        trimmedPending.isNotEmpty &&
        trimmedPending != current.familyName;
    if (!hasNameChange && current.pendingRemovals.isEmpty) return;

    emit(const FamilySettingsSaving());

    try {
      // Get family ID
      final familyIdResult = await _getMyFamilyIdUsecase();
      if (familyIdResult.isLeft()) {
        _emitIfOpen(
          const FamilySettingsError(code: FamilySettingsErrorCode.saveFailed),
        );
        return;
      }
      final familyId = familyIdResult.fold((_) => null, (id) => id);

      if (familyId == null) {
        _emitIfOpen(
          const FamilySettingsError(code: FamilySettingsErrorCode.notFound),
        );
        return;
      }

      // Update family name if changed (blank pending names are skipped).
      if (hasNameChange) {
        final nameResult = await _updateFamilyNameUsecase(
          familyId: familyId,
          name: trimmedPending,
        );
        if (nameResult.isLeft()) {
          _emitIfOpen(
            const FamilySettingsError(code: FamilySettingsErrorCode.saveFailed),
          );
          return;
        }
      }

      // Remove members
      for (final memberId in current.pendingRemovals) {
        final removeResult = await _removeMemberUsecase(
          familyId: familyId,
          userId: memberId,
        );
        if (removeResult.isLeft()) {
          _emitIfOpen(
            const FamilySettingsError(code: FamilySettingsErrorCode.saveFailed),
          );
          return;
        }
      }

      _emitIfOpen(const FamilySettingsSaveSuccess());

      // Reload settings after save
      await loadSettings();
    } on Object catch (_) {
      _emitIfOpen(
        const FamilySettingsError(code: FamilySettingsErrorCode.saveFailed),
      );
    }
  }

  Future<void> leaveFamily() async {
    if (state is! FamilySettingsLoaded) return;

    final current = state as FamilySettingsLoaded;

    // Block leaving when it would orphan the circle: the sole member must
    // delete it instead, and the last admin must transfer ownership (or
    // delete) first.
    if (current.members.length <= 1) {
      emit(const FamilySettingsError(code: FamilySettingsErrorCode.soleMember));
      return;
    }
    if (current.isAdmin && _isLastAdmin(current)) {
      emit(const FamilySettingsError(code: FamilySettingsErrorCode.lastAdmin));
      return;
    }

    emit(const FamilySettingsSaving());

    try {
      // Get family ID
      final familyIdResult = await _getMyFamilyIdUsecase();
      if (familyIdResult.isLeft()) {
        _emitIfOpen(
          const FamilySettingsError(code: FamilySettingsErrorCode.leaveFailed),
        );
        return;
      }
      final familyId = familyIdResult.fold((_) => null, (id) => id);

      if (familyId == null) {
        _emitIfOpen(
          const FamilySettingsError(code: FamilySettingsErrorCode.notFound),
        );
        return;
      }

      final userId = _authService.currentUserId;
      if (userId == null || userId.isEmpty) {
        _emitIfOpen(
          const FamilySettingsError(code: FamilySettingsErrorCode.notFound),
        );
        return;
      }

      // removeMember also deletes the user's notes and reminders in this
      // family (see PeopleRepositoryImpl.removeMember).
      final result = await _removeMemberUsecase(
        familyId: familyId,
        userId: userId,
      );
      result.fold(
        (_) => _emitIfOpen(
          const FamilySettingsError(code: FamilySettingsErrorCode.leaveFailed),
        ),
        (_) => _emitIfOpen(const FamilySettingsLeaveSuccess()),
      );
    } on Object catch (_) {
      _emitIfOpen(
        const FamilySettingsError(code: FamilySettingsErrorCode.leaveFailed),
      );
    }
  }

  Future<void> deleteFamily() async {
    if (state is! FamilySettingsLoaded) return;

    final current = state as FamilySettingsLoaded;
    if (!_requireAdmin(current)) return;

    emit(const FamilySettingsSaving());

    try {
      // Get family ID
      final familyIdResult = await _getMyFamilyIdUsecase();
      if (familyIdResult.isLeft()) {
        _emitIfOpen(
          const FamilySettingsError(code: FamilySettingsErrorCode.deleteFailed),
        );
        return;
      }
      final familyId = familyIdResult.fold((_) => null, (id) => id);

      if (familyId == null) {
        _emitIfOpen(
          const FamilySettingsError(code: FamilySettingsErrorCode.notFound),
        );
        return;
      }

      final result = await _deleteFamilyUsecase(familyId: familyId);
      result.fold(
        (_) => _emitIfOpen(
          const FamilySettingsError(code: FamilySettingsErrorCode.deleteFailed),
        ),
        (_) => _emitIfOpen(const FamilySettingsDeleteSuccess()),
      );
    } on Object catch (_) {
      _emitIfOpen(
        const FamilySettingsError(code: FamilySettingsErrorCode.deleteFailed),
      );
    }
  }

  bool _isLastAdmin(FamilySettingsLoaded current) {
    final adminCount = current.members.where(_isAdminRole).length;
    if (adminCount != 1) return false;
    return current.members.any(
      (m) => m.id == current.currentUserId && _isAdminRole(m),
    );
  }

  bool _isAdminRole(PersonEntity person) {
    final role = person.role?.toLowerCase();
    return role == 'admin' || role == 'owner';
  }
}
