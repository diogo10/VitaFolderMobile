import 'package:house_mira/features/people/domain/entities/person_entity.dart';

sealed class FamilySettingsState {
  const FamilySettingsState();
}

class FamilySettingsInitial extends FamilySettingsState {
  const FamilySettingsInitial();
}

class FamilySettingsLoading extends FamilySettingsState {
  const FamilySettingsLoading();
}

class FamilySettingsLoaded extends FamilySettingsState {

  const FamilySettingsLoaded({
    required this.familyName,
    required this.members,
    required this.currentUserId,
    this.pendingFamilyName,
    this.pendingRemovals = const {},
  });
  final String familyName;
  final List<PersonEntity> members;
  final String currentUserId;
  final String? pendingFamilyName;
  final Set<String> pendingRemovals;

  FamilySettingsLoaded copyWith({
    String? familyName,
    List<PersonEntity>? members,
    String? currentUserId,
    String? pendingFamilyName,
    Set<String>? pendingRemovals,
  }) {
    return FamilySettingsLoaded(
      familyName: familyName ?? this.familyName,
      members: members ?? this.members,
      currentUserId: currentUserId ?? this.currentUserId,
      pendingFamilyName: pendingFamilyName ?? this.pendingFamilyName,
      pendingRemovals: pendingRemovals ?? this.pendingRemovals,
    );
  }

  bool get hasPendingChanges =>
      pendingFamilyName != null || pendingRemovals.isNotEmpty;

  List<PersonEntity> get displayMembers {
    if (pendingRemovals.isEmpty) return members;
    return members.where((m) => !pendingRemovals.contains(m.id)).toList();
  }
}

class FamilySettingsSaving extends FamilySettingsState {
  const FamilySettingsSaving();
}

class FamilySettingsSaveSuccess extends FamilySettingsState {
  const FamilySettingsSaveSuccess();
}

class FamilySettingsDeleteSuccess extends FamilySettingsState {
  const FamilySettingsDeleteSuccess();
}

enum FamilySettingsErrorCode { notAdmin, notFound }

class FamilySettingsError extends FamilySettingsState {

  const FamilySettingsError({this.message, this.code});
  final String? message;
  final FamilySettingsErrorCode? code;
}
