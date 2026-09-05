import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/widgets/sand/sand_header.dart';
import 'package:house_mira/core/widgets/sand/sand_primary_button.dart';
import 'package:house_mira/core/widgets/sand/sand_text_field.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/people/presentation/cubit/family_settings_cubit.dart';
import 'package:house_mira/features/people/presentation/cubit/family_settings_state.dart';
import 'package:house_mira/features/people/presentation/widgets/family_member_settings_tile.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/sand_palette.dart';

class FamilySettingsScreen extends StatefulWidget {
  const FamilySettingsScreen({super.key});

  @override
  State<FamilySettingsScreen> createState() => _FamilySettingsScreenState();
}

class _FamilySettingsScreenState extends State<FamilySettingsScreen> {
  final _familyNameController = TextEditingController();
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    context.read<FamilySettingsCubit>().loadSettings();
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return BlocConsumer<FamilySettingsCubit, FamilySettingsState>(
      listener: (context, state) {
        if (state is FamilySettingsLoaded && !_hasInitialized) {
          _hasInitialized = true;
          _familyNameController.text = state.familyName;
        }
        if (state is FamilySettingsSaveSuccess) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l.saveSuccess)));
        }
        if (state is FamilySettingsDeleteSuccess) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l.deleteSuccess)));
          context.go('/account');
        }
        if (state is FamilySettingsError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isLoading =
            state is FamilySettingsLoading || state is FamilySettingsSaving;

        if (state is FamilySettingsError) {
          return Scaffold(
            backgroundColor: SandPalette.sand50,
            body: SafeArea(
              child: Column(
                children: [
                  SandHeader(title: l.familySettingsTitle),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            state.message,
                            style: const TextStyle(color: SandPalette.sand500),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => context
                                .read<FamilySettingsCubit>()
                                .loadSettings(),
                            child: Text(l.ok),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is! FamilySettingsLoaded) {
          return Scaffold(
            backgroundColor: SandPalette.sand50,
            body: SafeArea(
              child: Column(
                children: [
                  SandHeader(title: l.familySettingsTitle),
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            ),
          );
        }

        final loaded = state;
        final displayMembers = loaded.displayMembers;
        final hasPendingChanges = loaded.hasPendingChanges;

        return Scaffold(
          backgroundColor: SandPalette.sand50,
          body: SafeArea(
            child: Column(
              children: [
                SandHeader(title: l.familySettingsTitle),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Family Name Section
                        _FamilyNameSection(
                          controller: _familyNameController,
                          label: l.familyNameLabel,
                          hint: l.familyNameHint,
                          onChanged: (value) => context
                              .read<FamilySettingsCubit>()
                              .queueFamilyNameChange(value),
                        ),

                        const SizedBox(height: 24),
                        Divider(height: 1, color: SandPalette.sand100),
                        const SizedBox(height: 24),

                        // Manage Members Section
                        _ManageMembersSection(
                          members: displayMembers,
                          currentUserId: loaded.currentUserId,
                          familyName: loaded.familyName,
                          memberCount: displayMembers.length,
                          onRemoveMember: (memberId, memberName) =>
                              _showRemoveMemberDialog(
                                context,
                                memberId,
                                memberName,
                              ),
                          isRemoving: isLoading,
                          l: l,
                        ),

                        const SizedBox(height: 32),

                        // Danger Zone
                        _DangerZoneSection(
                          familyName: loaded.familyName,
                          onDeletePressed: () => _showDeleteFamilyDialog(
                            context,
                            loaded.familyName,
                          ),
                          isDeleting: isLoading,
                          l: l,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        SandPalette.sand50.withValues(alpha: 0),
                        SandPalette.sand50,
                        SandPalette.sand50,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SandPrimaryButton(
                      label: isLoading ? l.savedButton : l.saveButton,
                      icon: Icons.check_rounded,
                      isLoading: isLoading,
                      onPressed: hasPendingChanges && !isLoading
                          ? () => context
                                .read<FamilySettingsCubit>()
                                .saveChanges()
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRemoveMemberDialog(
    BuildContext context,
    String memberId,
    String memberName,
  ) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<FamilySettingsCubit>();
    final state = cubit.state;

    if (state is FamilySettingsLoaded) {
      final familyName = state.familyName;

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l.removeMemberConfirm(memberName, familyName),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                cubit.queueMemberRemoval(memberId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l.deleteFamilyButton),
            ),
          ],
        ),
      );
    }
  }

  void _showDeleteFamilyDialog(BuildContext context, String familyName) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<FamilySettingsCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.deleteFamilyTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        content: Text(
          l.deleteFamilyDescription,
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.deleteFamily();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l.deleteFamilyButton),
          ),
        ],
      ),
    );
  }
}

class _FamilyNameSection extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String> onChanged;

  const _FamilyNameSection({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<_FamilyNameSection> createState() => _FamilyNameSectionState();
}

class _FamilyNameSectionState extends State<_FamilyNameSection> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            color: SandPalette.sand500,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        SandLabeledField(
          controller: widget.controller,
          label: '',
          hint: widget.hint,
          prefixIcon: Icons.edit_rounded,
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }
}

class _ManageMembersSection extends StatelessWidget {
  final List<PersonEntity> members;
  final String currentUserId;
  final String familyName;
  final int memberCount;
  final Function(String memberId, String memberName) onRemoveMember;
  final bool isRemoving;
  final AppLocalizations l;

  const _ManageMembersSection({
    required this.members,
    required this.currentUserId,
    required this.familyName,
    required this.memberCount,
    required this.onRemoveMember,
    required this.isRemoving,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.manageMembersTitle,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                color: SandPalette.sand700,
                fontSize: 14,
              ),
            ),
            Text(
              l.memberCount(memberCount),
              style: TextStyle(
                fontFamily: 'Figtree',
                fontWeight: FontWeight.w500,
                color: SandPalette.sand300,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._buildMemberTiles(
          members,
          currentUserId,
          familyName,
          onRemoveMember,
          isRemoving,
        ),
      ],
    );
  }

  List<Widget> _buildMemberTiles(
    List<PersonEntity> members,
    String currentUserId,
    String familyName,
    Function(String memberId, String memberName) onRemoveMember,
    bool isRemoving,
  ) {
    return members.asMap().entries.map((entry) {
      final index = entry.key;
      final person = entry.value;
      return Padding(
        padding: EdgeInsets.only(bottom: index < members.length - 1 ? 8 : 0),
        child: FamilyMemberSettingsTile(
          person: person,
          currentUserId: currentUserId,
          familyName: familyName,
          onRemove: person.id != currentUserId
              ? () => onRemoveMember(person.id!, person.name ?? '')
              : null,
          isRemoving: isRemoving,
        ),
      );
    }).toList();
  }
}

class _DangerZoneSection extends StatelessWidget {
  final String familyName;
  final VoidCallback onDeletePressed;
  final bool isDeleting;
  final AppLocalizations l;

  const _DangerZoneSection({
    required this.familyName,
    required this.onDeletePressed,
    required this.isDeleting,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.dangerZoneTitle,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            color: Colors.red,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFDF2F2),
            border: Border.all(color: const Color(0xFFFAD1D1)),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.deleteFamilyTitle,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.deleteFamilyDescription,
                style: TextStyle(
                  fontFamily: 'Figtree',
                  color: const Color(0xFFF47174),
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: isDeleting ? null : onDeletePressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Color(0xFFFAD1D1)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  child: Text(
                    l.deleteFamilyButton,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
