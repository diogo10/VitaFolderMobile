import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vita_folder_mobile/core/injections/service_locator.dart';
import 'package:vita_folder_mobile/features/people/data/datasource/people_local_datasource.dart';
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
  bool _inviteCodeCardDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadDismissedState();
  }

  Future<void> _loadDismissedState() async {
    final datasource = slInstance<PeopleLocalDatasource>(
      instanceName: 'peopleLocalDatasource',
    );
    final dismissed = await datasource.isInviteCodeCardDismissed();
    if (mounted) {
      setState(() => _inviteCodeCardDismissed = dismissed);
    }
  }

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

  Future<void> _closeInviteCodeCard() async {
    final datasource = slInstance<PeopleLocalDatasource>(
      instanceName: 'peopleLocalDatasource',
    );
    await datasource.dismissInviteCodeCard();
    if (mounted) {
      setState(() => _inviteCodeCardDismissed = true);
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
              if (!_inviteCodeCardDismissed) ...[
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
                    onClose: () => _closeInviteCodeCard(),
                  ),
                ),
                const SizedBox(height: 26),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
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
              const SizedBox(height: 14),
              FamilyMemberCardWidget(
                name: 'Sarah Smith',
                relationship: 'Mom',
                detail: 'sarah@smith.com',
                status: 'Active now',
                role: FamilyMemberRole.admin,
                avatarColor: const Color(0xFF70969A),
                statusColor: const Color(0xFF53B77A),
                onPressed: () =>
                    _showMessage(l.peopleLoadedMemberSelected('Sarah Smith')),
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
                onPressed: () =>
                    _showMessage(l.peopleLoadedMemberSelected('James Smith')),
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
                onPressed: () =>
                    _showMessage(l.peopleLoadedMemberSelected('Lily Smith')),
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
                onPressed: () =>
                    _showMessage(l.peopleLoadedMemberSelected('Max Smith')),
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
                onPressed: () =>
                    _showMessage(l.peopleLoadedMemberSelected('Rose Smith')),
              ),
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
