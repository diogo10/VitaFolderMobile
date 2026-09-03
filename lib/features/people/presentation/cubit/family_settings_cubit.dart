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
  final GetPeopleUsecase _getPeopleUsecase;
  final GetMyFamilyIdUsecase _getMyFamilyIdUsecase;
  final UpdateFamilyNameUsecase _updateFamilyNameUsecase;
  final RemoveMemberUsecase _removeMemberUsecase;
  final DeleteFamilyUsecase _deleteFamilyUsecase;
  final AuthService _authService;

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

  Future<void> loadSettings() async {
    emit(const FamilySettingsLoading());

    try {
      final result = await _getPeopleUsecase();

      result.fold(
        (error) => emit(FamilySettingsError(message: error.toString())),
        (peopleData) {
          final currentUserId = _authService.currentUserId ?? '';

          // Check if user is admin
          final currentUserRole = peopleData.people
              .firstWhere(
                (p) => p.id == currentUserId,
                orElse: () => PersonEntity(),
              )
              .role;

          if (currentUserRole?.toLowerCase() != 'admin') {
            emit(
              const FamilySettingsError(
                message: 'Only family admins can access family settings.',
              ),
            );
            return;
          }

          emit(
            FamilySettingsLoaded(
              familyName: peopleData.family.name,
              members: peopleData.people,
              currentUserId: currentUserId,
            ),
          );
        },
      );
    } catch (e) {
      emit(FamilySettingsError(message: e.toString()));
    }
  }

  void queueFamilyNameChange(String name) {
    if (state is FamilySettingsLoaded) {
      final current = state as FamilySettingsLoaded;
      emit(current.copyWith(pendingFamilyName: name.trim()));
    }
  }

  void queueMemberRemoval(String memberId) {
    if (state is FamilySettingsLoaded) {
      final current = state as FamilySettingsLoaded;
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
    if (!current.hasPendingChanges) return;

    emit(const FamilySettingsSaving());

    try {
      // Get family ID
      final familyIdResult = await _getMyFamilyIdUsecase();
      final familyId = familyIdResult.fold(
        (error) => throw Exception(error.toString()),
        (id) => id,
      );

      if (familyId == null) {
        emit(const FamilySettingsError(message: 'Family not found'));
        return;
      }

      // Update family name if changed
      if (current.pendingFamilyName != null &&
          current.pendingFamilyName != current.familyName) {
        final nameResult = await _updateFamilyNameUsecase(
          familyId: familyId,
          name: current.pendingFamilyName!,
        );
        nameResult.fold((error) => throw Exception(error.toString()), (_) {});
      }

      // Remove members
      for (final memberId in current.pendingRemovals) {
        final removeResult = await _removeMemberUsecase(
          familyId: familyId,
          userId: memberId,
        );
        removeResult.fold((error) => throw Exception(error.toString()), (_) {});
      }

      emit(const FamilySettingsSaveSuccess());

      // Reload settings after save
      await loadSettings();
    } catch (e) {
      emit(FamilySettingsError(message: e.toString()));
    }
  }

  Future<void> deleteFamily() async {
    if (state is! FamilySettingsLoaded) return;

    emit(const FamilySettingsSaving());

    try {
      // Get family ID
      final familyIdResult = await _getMyFamilyIdUsecase();
      final familyId = familyIdResult.fold(
        (error) => throw Exception(error.toString()),
        (id) => id,
      );

      if (familyId == null) {
        emit(const FamilySettingsError(message: 'Family not found'));
        return;
      }

      final result = await _deleteFamilyUsecase(familyId: familyId);
      result.fold(
        (error) => emit(FamilySettingsError(message: error.toString())),
        (_) => emit(const FamilySettingsDeleteSuccess()),
      );
    } catch (e) {
      emit(FamilySettingsError(message: e.toString()));
    }
  }
}
