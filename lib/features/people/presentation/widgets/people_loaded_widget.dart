import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/person_entity.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/people_cubit.dart';
import 'package:vita_folder_mobile/features/people/presentation/widgets/add_family_member_card_widget.dart';
import 'package:vita_folder_mobile/features/people/presentation/widgets/family_member_card_widget.dart';
import 'package:vita_folder_mobile/features/people/presentation/widgets/family_header_widget.dart';
import 'package:vita_folder_mobile/features/people/presentation/widgets/invite_code_card_widget.dart';
import 'package:vita_folder_mobile/features/people/presentation/widgets/role_permissions_card_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class PeopleLoadedWidget extends StatefulWidget {
  final List<PersonEntity> people;
  final String inviteCode;
  final String familyName;

  const PeopleLoadedWidget({
    super.key,
    required this.people,
    required this.inviteCode,
    required this.familyName,
  });

  @override
  State<PeopleLoadedWidget> createState() => _PeopleLoadedWidgetState();
}

class _PeopleLoadedWidgetState extends State<PeopleLoadedWidget> {
  Future<void> _copyToClipboard(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    _showMessage(message);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<Widget> _buildMemberCards(AppLocalizations l) {
    final colors = <FamilyMemberRole, Color>{
      FamilyMemberRole.admin: const Color(0xFF70969A),
      FamilyMemberRole.parent: const Color(0xFF3D76A8),
      FamilyMemberRole.child: const Color(0xFFB47D88),
      FamilyMemberRole.member: const Color(0xFF8A7592),
    };
    final statusColors = <FamilyMemberRole, Color>{
      FamilyMemberRole.admin: const Color(0xFF53B77A),
      FamilyMemberRole.parent: const Color(0xFF5D9DF5),
      FamilyMemberRole.child: const Color(0xFFB56AF4),
      FamilyMemberRole.member: const Color(0xFF45C76C),
    };

    final cards = <Widget>[];
    for (int i = 0; i < widget.people.length; i++) {
      if (i > 0) cards.add(const SizedBox(height: 10));
      final person = widget.people[i];
      final role = _roleFromString(person.role);
      cards.add(
        FamilyMemberCardWidget(
          key: ValueKey(person.id ?? i),
          name: person.name ?? '',
          relationship: _relationshipFromRole(person.role),
          detail: person.email ?? person.phone ?? '',
          status: 'Active',
          role: role,
          avatarColor: colors[role]!,
          statusColor: statusColors[role]!,
          onPressed: () => _showMessage(
            l.peopleLoadedMemberSelected(person.name ?? ''),
          ),
        ),
      );
    }
    return cards;
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

  String _relationshipFromRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'parent':
        return 'Parent';
      case 'child':
        return 'Child';
      default:
        return 'Member';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ColoredBox(
      color: const Color(0xFFFFFCF8),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<PeopleCubit>().getPeople(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              FamilyHeaderWidget(
                onNotificationsPressed: () =>
                    _showMessage(l.peopleLoadedNotificationMessage),
                onProfilePressed: () =>
                    _showMessage(l.peopleLoadedProfileMessage),
              ),
              const SizedBox(height: 26),
              Text(
                l.peopleLoadedTheCircle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF604B38),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l.peopleLoadedMembersCount(widget.people.length, widget.familyName),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFB0906C),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: InviteCodeCardWidget(
                  code: widget.inviteCode,
                  expiresInDays: 6,
                  onCopyPressed: () => _copyToClipboard(
                    widget.inviteCode,
                    l.peopleLoadedInviteCodeCopied,
                  ),
                  onSharePressed: () => _copyToClipboard(
                    'https://vitafolder.app/invite/'
                    '${widget.inviteCode.replaceAll('•', '')}',
                    l.peopleLoadedInviteLinkCopied,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.peopleLoadedMembersTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF604B38),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ..._buildMemberCards(l),
              const SizedBox(height: 12),
              AddFamilyMemberCardWidget(
                onPressed: () => context.push('/invite-people'),
              ),
              const SizedBox(height: 16),
              RolePermissionsCardWidget(
                onLearnMorePressed: () =>
                    context.go("/account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
