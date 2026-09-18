import 'package:flutter/material.dart';
import 'package:house_mira/features/people/domain/entities/person_entity.dart';
import 'package:house_mira/features/people/presentation/widgets/family_member_card_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';

class HomeCircleWidget extends StatelessWidget {

  const HomeCircleWidget({
    required this.people, super.key,
    this.onManagePressed,
  });
  final List<PersonEntity> people;
  final VoidCallback? onManagePressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.homeEmptyFooterCircleTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: onManagePressed,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF604B38),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.homeSuccessCircleManage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF604B38),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Color(0xFF604B38),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: people.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final person = people[index];
              return _CircleAvatarItem(
                person: person,
                role: _roleFromString(person.role),
              );
            },
          ),
        ),
      ],
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
}

class _CircleAvatarItem extends StatelessWidget {

  const _CircleAvatarItem({required this.person, required this.role});
  final PersonEntity person;
  final FamilyMemberRole role;

  @override
  Widget build(BuildContext context) {
    final name = person.name ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: role.foregroundColor.withValues(alpha: 0.2),
          child: Text(
            _initials(name),
            style: TextStyle(
              color: role.foregroundColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 56,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _initials(String value) {
    if (value.isEmpty) return '';
    final words = value.trim().split(RegExp(r'\s+'));
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}
