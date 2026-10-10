import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/local_storage/local_storage_datasource.dart';
import 'package:house_mira/features/people/presentation/cubit/people_cubit.dart';
import 'package:house_mira/features/people/presentation/cubit/people_state.dart';
import 'package:house_mira/features/people/presentation/widgets/people_empty_widget.dart';
import 'package:house_mira/features/people/presentation/widgets/people_loaded_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';

class PeopleView extends StatefulWidget {
  const PeopleView({
    required this.storage,
    super.key,
    this.pendingInviteCode,
    this.onJoined,
  });

  /// Invite code from a `/invite/<code>` deep link, pre-filled into the
  /// join form so the recipient can join with one tap. `null` (or blank)
  /// means no deep link is pending.
  final String? pendingInviteCode;

  /// Called once the user successfully joins a family (state reaches
  /// [PeopleLoaded] after a join). Route builders wire this to
  /// `TabRefreshCoordinator.refreshAll` so sibling tabs reload.
  final VoidCallback? onJoined;

  /// Dismissal-flag store forwarded to [PeopleLoadedWidget];
  /// resolved by name at the router composition root, never via GetIt
  /// in the widget tree.
  final LocalStorageDatasource storage;

  @override
  State<PeopleView> createState() => _PeopleViewState();
}

class _PeopleViewState extends State<PeopleView> {
  final _familyNameController = TextEditingController();

  /// True between tapping join and the outcome landing, so the success
  /// confirmation fires only for a fresh join — not for initial loads or
  /// pull-to-refresh.
  var _joinPending = false;

  void _onCreateFamilyPressed() {
    final authService = context.read<AuthService>();
    if (!authService.isLoggedIn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.needToBeLoggedIn)),
      );
      return;
    }

    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.peopleViewCreateFamily),
          content: TextField(
            controller: _familyNameController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.peopleViewFamilyNameHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _familyNameController.clear();
                Navigator.of(dialogContext).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () async {
                final name = _familyNameController.text.trim();
                if (name.isNotEmpty) {
                  final navigator = Navigator.of(dialogContext);
                  await context.read<PeopleCubit>().createFamily(name: name);
                  _familyNameController.clear();
                  navigator.pop();
                }
              },
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(context.read<PeopleCubit>().getPeople());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PeopleCubit, PeopleState>(
      listener: (context, state) {
        if (state is PeopleInvalidFamilyCode) {
          _joinPending = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.peopleInvalidFamilyCode,
              ),
            ),
          );
        } else if (state is PeopleLoaded && _joinPending) {
          _joinPending = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.peopleJoinedFamily),
            ),
          );
          widget.onJoined?.call();
        }
      },
      builder: (context, state) {
        if (state is PeopleError) {
          return Center(
            child: FilledButton.icon(
              onPressed: context.read<PeopleCubit>().getPeople,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context)!.peopleViewTryAgain),
            ),
          );
        }

        if (state is PeopleEmpty || state is PeopleInvalidFamilyCode) {
          return PeopleEmptyWidget(
            initialInviteCode: widget.pendingInviteCode,
            onCreateFamilyPressed: _onCreateFamilyPressed,
            onJoinFamilyPressed: (code) {
              _joinPending = true;
              unawaited(
                context.read<PeopleCubit>().joinFamily(familyCode: code),
              );
            },
            onRefresh: () =>
                context.read<PeopleCubit>().getPeople(isRefresh: true),
          );
        }

        if (state is! PeopleLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return PeopleLoadedWidget(
          people: state.people,
          inviteCode: state.inviteCode,
          familyName: state.familyName,
          storage: widget.storage,
        );
      },
    );
  }
}
