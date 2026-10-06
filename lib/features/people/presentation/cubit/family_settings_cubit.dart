import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/people/domain/usecase/delete_family_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/get_my_family_id_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/get_people_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/remove_member_usecase.dart';
import 'package:house_mira/features/people/domain/usecase/update_family_name_usecase.dart';
import 'package:house_mira/features/people/presentation/cubit/family_settings_state.dart';

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

  Future<void> loadSettings() async {
    emit(const FamilySettingsLoading());

    try {
      final result = await _getPeopleUsecase();

      result.fold(
        (error) => emit(
          const FamilySettingsError(code: FamilySettingsErrorCode.loadFailed),
        ),
        (peopleData) {
          final currentUserId = _authService.currentUserId ?? '';

          // Admins manage the circle; every member may still open settings
          // to leave it. The view gates admin-only actions on [isAdmin];
          // the queue/save/delete guards below re-check it so a crafted
          // call cannot bypass the UI. Supabase RLS is the backend
          // enforcement point: families update/delete must be admin-only
          // and family_memberships delete-others must be admin-only.
          final currentUserRole = peopleData.people
              .firstWhere(
                (p) => p.id == currentUserId,
                orElse: PersonEntity.new,
              )
              .role;
          final role = currentUserRole?.toLowerCase();
          final isAdmin = role == 'admin' || role == 'owner';

          emit(
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
      emit(const FamilySettingsError(code: FamilySettingsErrorCode.loadFailed));
    }
  }

  /// Emits a notAdmin error when [current] is not an admin.
  /// Cubit-level defense-in-depth: the view hides admin actions, RLS
  /// enforces them backend-side; this keeps a non-admin programmatic call
  /// from reaching the repository.
  bool _requireAdmin(FamilySettingsLoaded current) {
    if (!current.isAdmin) {
      emit(const FamilySettingsError(code: FamilySettingsErrorCode.notAdmin));
      return false;
    }
    return true;
  }

  void queueFamilyNameChange(String name) {
    if (state is FamilySettingsLoaded) {
      final current = state as FamilySettingsLoaded;
      if (!_requireAdmin(current)) return;
      emit(current.copyWith(pendingFamilyName: name.trim()));
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
      final newRemovals = Set<String>.from(current.pendingRemovals)
        ..remove(memberId);
      emit(current.copyWith(pendingRemovals: newRemovals));
    }
  }

  Future<void> saveChanges() async {
    if (state is! FamilySettingsLoaded) return;

    final current = state as FamilySettingsLoaded;
    if (!_requireAdmin(current)) return;
    if (!current.hasPendingChanges) return;

    emit(const FamilySettingsSaving());

    try {
      // Get family ID
      final familyIdResult = await _getMyFamilyIdUsecase();
      if (familyIdResult.isLeft()) {
        emit(
          const FamilySettingsError(code: FamilySettingsErrorCode.saveFailed),
        );
        return;
      }
      final familyId = familyIdResult.fold((_) => null, (id) => id);

      if (familyId == null) {
        emit(const FamilySettingsError(code: FamilySettingsErrorCode.notFound));
        return;
      }

      // Update family name if changed
      if (current.pendingFamilyName != null &&
          current.pendingFamilyName != current.familyName) {
        final nameResult = await _updateFamilyNameUsecase(
          familyId: familyId,
          name: current.pendingFamilyName!,
        );
        if (nameResult.isLeft()) {
          emit(
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
          emit(
            const FamilySettingsError(code: FamilySettingsErrorCode.saveFailed),
          );
          return;
        }
      }

      emit(const FamilySettingsSaveSuccess());

      // Reload settings after save
      await loadSettings();
    } on Object catch (_) {
      emit(const FamilySettingsError(code: FamilySettingsErrorCode.saveFailed));
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
        emit(
          const FamilySettingsError(code: FamilySettingsErrorCode.leaveFailed),
        );
        return;
      }
      final familyId = familyIdResult.fold((_) => null, (id) => id);

      if (familyId == null) {
        emit(const FamilySettingsError(code: FamilySettingsErrorCode.notFound));
        return;
      }

      final userId = _authService.currentUserId;
      if (userId == null || userId.isEmpty) {
        emit(const FamilySettingsError(code: FamilySettingsErrorCode.notFound));
        return;
      }

      // removeMember also deletes the user's notes and reminders in this
      // family (see PeopleRepositoryImpl.removeMember).
      final result = await _removeMemberUsecase(
        familyId: familyId,
        userId: userId,
      );
      result.fold(
        (_) => emit(
          const FamilySettingsError(code: FamilySettingsErrorCode.leaveFailed),
        ),
        (_) => emit(const FamilySettingsLeaveSuccess()),
      );
    } on Object catch (_) {
      emit(
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
        emit(
          const FamilySettingsError(code: FamilySettingsErrorCode.deleteFailed),
        );
        return;
      }
      final familyId = familyIdResult.fold((_) => null, (id) => id);

      if (familyId == null) {
        emit(const FamilySettingsError(code: FamilySettingsErrorCode.notFound));
        return;
      }

      final result = await _deleteFamilyUsecase(familyId: familyId);
      result.fold(
        (_) => emit(
          const FamilySettingsError(code: FamilySettingsErrorCode.deleteFailed),
        ),
        (_) => emit(const FamilySettingsDeleteSuccess()),
      );
    } on Object catch (_) {
      emit(
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
