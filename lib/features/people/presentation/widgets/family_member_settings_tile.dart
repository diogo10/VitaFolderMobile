import 'package:flutter/material.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/people/presentation/widgets/family_member_card_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/sand_palette.dart';

class FamilyMemberSettingsTile extends StatelessWidget {
  const FamilyMemberSettingsTile({
    required this.person,
    required this.currentUserId,
    required this.familyName,
    super.key,
    this.onRemove,
    this.isRemoving = false,
  });
  final PersonEntity person;
  final String currentUserId;
  final String familyName;
  final VoidCallback? onRemove;
  final bool isRemoving;

  bool get isCurrentUser => person.id == currentUserId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final role = _roleFromString(person.role);
    final (avatarColor, roleColor) = _colorsForRole(role);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SandPalette.sand100),
        boxShadow: [
          BoxShadow(
            color: SandPalette.sand500.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: avatarColor,
              child: Text(
                _initials(person.name ?? ''),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Name and role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          person.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: SandPalette.sand700,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: SandPalette.sand100,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            l.youBadge,
                            style: const TextStyle(
                              color: SandPalette.sand400,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.$1,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            _roleLabel(role, l),
                            style: TextStyle(
                              color: roleColor.$2,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Remove button (not for current user)
            if (!isCurrentUser)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isRemoving ? null : onRemove,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_remove_rounded,
                      color: Color(0xFFF47174),
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  FamilyMemberRole _roleFromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return FamilyMemberRole.admin;
      case 'parent':
        return FamilyMemberRole.parent;
      case 'child':
        return FamilyMemberRole.child;
      default:
        return FamilyMemberRole.member;
    }
  }

  (Color, (Color, Color)) _colorsForRole(FamilyMemberRole role) {
    switch (role) {
      case FamilyMemberRole.admin:
        return (
          const Color(0xFF70969A),
          (const Color(0xFFF6D584), const Color(0xFF9B6500)),
        );
      case FamilyMemberRole.parent:
        return (
          const Color(0xFF3D76A8),
          (const Color(0xFFD9E8FF), const Color(0xFF3974C9)),
        );
      case FamilyMemberRole.child:
        return (
          const Color(0xFFB47D88),
          (const Color(0xFFE8DFFF), const Color(0xFF6D4BD2)),
        );
      case FamilyMemberRole.member:
        return (
          const Color(0xFF8A7592),
          (const Color(0xFFD9F5EA), const Color(0xFF27835F)),
        );
    }
  }

  String _roleLabel(FamilyMemberRole role, AppLocalizations l) {
    switch (role) {
      case FamilyMemberRole.admin:
        return l.roleAdmin;
      case FamilyMemberRole.parent:
        return l.roleParent;
      case FamilyMemberRole.child:
        return l.roleChild;
      case FamilyMemberRole.member:
        return l.roleMember;
    }
  }

  String _initials(String value) {
    if (value.isEmpty) return '';
    final words = value.trim().split(RegExp(r'\s+'));
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}
