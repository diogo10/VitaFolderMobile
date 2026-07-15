import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/people/domain/entities/person_entity.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/people_cubit.dart';
import 'package:vita_folder_mobile/features/people/presentation/widgets/add_family_member_card_widget.dart';
import 'package:vita_folder_mobile/features/people/presentation/widgets/family_member_card_widget.dart';
import 'package:vita_folder_mobile/features/people/presentation/widgets/family_header_widget.dart';
import 'package:vita_folder_mobile/features/people/presentation/widgets/invite_code_card_widget.dart';
import 'package:vita_folder_mobile/features/people/presentation/widgets/pending_invite_card_widget.dart';
import 'package:vita_folder_mobile/features/people/presentation/widgets/role_permissions_card_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class PeopleLoadedWidget extends StatefulWidget {
  final List<PersonEntity> people;

  const PeopleLoadedWidget({super.key, required this.people});

  @override
  State<PeopleLoadedWidget> createState() => _PeopleLoadedWidgetState();
}

class _PeopleLoadedWidgetState extends State<PeopleLoadedWidget> {
  static const _inviteCodes = ['SM•4829', 'SM•7351', 'SM•9064'];
  int _inviteCodeIndex = 0;

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
                onProfilePressed: () => _showMessage(l.peopleLoadedProfileMessage),
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
                l.peopleLoadedMembersCount(widget.people.length),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFB0906C),
                ),
              ),
              const SizedBox(height: 22),
              InviteCodeCardWidget(
                code: _inviteCodes[_inviteCodeIndex],
                expiresInDays: 6,
                onCopyPressed: () => _copyToClipboard(
                  _inviteCodes[_inviteCodeIndex].replaceAll('•', ''),
                  l.peopleLoadedInviteCodeCopied,
                ),
                onSharePressed: () => _copyToClipboard(
                  'https://vitafolder.app/invite/'
                      '${_inviteCodes[_inviteCodeIndex].replaceAll('•', '')}',
                  l.peopleLoadedInviteLinkCopied,
                ),
                onRefreshPressed: () {
                  setState(() {
                    _inviteCodeIndex =
                        (_inviteCodeIndex + 1) % _inviteCodes.length;
                  });
                  _showMessage(l.peopleLoadedInviteCodeRefreshed);
                },
              ),
              const SizedBox(height: 24),
              PendingInviteCardWidget(
                email: 'grandma@smith.com',
                sentAtLabel: l.peopleLoadedPendingInviteSent,
                onResendPressed: () =>
                    _showMessage(l.peopleLoadedInvitationSentAgain),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.peopleLoadedMembersTitle,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(
                            color: const Color(0xFF604B38),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showMessage(l.peopleLoadedAddMemberSelected),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF92724F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 16,
                    ),
                    label: Text(
                      l.peopleLoadedAddMemberButton,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FamilyMemberCardWidget(
                name: 'Sarah Smith',
                relationship: 'Mom',
                detail: 'sarah@smith.com',
                status: 'Active now',
                role: FamilyMemberRole.admin,
                avatarColor: const Color(0xFF70969A),
                statusColor: const Color(0xFF53B77A),
                onPressed: () => _showMessage(l.peopleLoadedMemberSelected('Sarah Smith')),
              ),
              const SizedBox(height: 10),
              FamilyMemberCardWidget(
                name: 'James Smith',
                relationship: 'Dad',
                detail: 'james@smith.com',
                status: 'At Work',
                role: FamilyMemberRole.parent,
                avatarColor: const Color(0xFF3D76A8),
                statusColor: const Color(0xFF5D9DF5),
                onPressed: () => _showMessage(l.peopleLoadedMemberSelected('James Smith')),
              ),
              const SizedBox(height: 10),
              FamilyMemberCardWidget(
                name: 'Lily Smith',
                relationship: 'Daughter',
                detail: 'Age 9',
                status: 'At School',
                role: FamilyMemberRole.child,
                avatarColor: const Color(0xFFB47D88),
                statusColor: const Color(0xFFB56AF4),
                onPressed: () => _showMessage(l.peopleLoadedMemberSelected('Lily Smith')),
              ),
              const SizedBox(height: 10),
              FamilyMemberCardWidget(
                name: 'Max Smith',
                relationship: 'Son',
                detail: 'Age 7',
                status: 'At School',
                role: FamilyMemberRole.child,
                avatarColor: const Color(0xFF7F8F82),
                statusColor: const Color(0xFFB56AF4),
                onPressed: () => _showMessage(l.peopleLoadedMemberSelected('Max Smith')),
              ),
              const SizedBox(height: 10),
              FamilyMemberCardWidget(
                name: 'Rose Smith',
                relationship: 'Grandma',
                detail: 'rose@smith.com',
                status: 'Last seen 2h ago',
                role: FamilyMemberRole.member,
                avatarColor: const Color(0xFF8A7592),
                statusColor: const Color(0xFF45C76C),
                onPressed: () => _showMessage(l.peopleLoadedMemberSelected('Rose Smith')),
              ),
              const SizedBox(height: 12),
              AddFamilyMemberCardWidget(
                onPressed: () => _showMessage(l.peopleLoadedAddFamilyMemberSelected),
              ),
              const SizedBox(height: 16),
              RolePermissionsCardWidget(
                onLearnMorePressed: () =>
                    _showMessage(l.peopleLoadedRolePermissionsSelected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
