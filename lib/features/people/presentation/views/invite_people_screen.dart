import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/features/people/presentation/cubit/invite_people_cubit.dart';
import 'package:house_mira/features/people/presentation/cubit/invite_people_state.dart';
import 'package:house_mira/generated/app_localizations.dart';

class InvitePeopleScreen extends StatefulWidget {
  const InvitePeopleScreen({super.key});

  @override
  State<InvitePeopleScreen> createState() => _InvitePeopleScreenState();
}

class _InvitePeopleScreenState extends State<InvitePeopleScreen> {
  final _emailController = TextEditingController();
  InviteRelationship _selectedRelationship = InviteRelationship.spouse;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _relationshipLabel(InviteRelationship rel, AppLocalizations l) {
    switch (rel) {
      case InviteRelationship.self:
        return l.invitePeopleRelationshipSelf;
      case InviteRelationship.spouse:
        return l.invitePeopleRelationshipSpouse;
      case InviteRelationship.child:
        return l.invitePeopleRelationshipChild;
      case InviteRelationship.parent:
        return l.invitePeopleRelationshipParent;
      case InviteRelationship.other:
        return l.invitePeopleRelationshipOther;
    }
  }

  void _handleSendInvite(AppLocalizations l) {
    final authService = context.read<AuthService>();
    if (!authService.isLoggedIn()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.needToBeLoggedIn)));
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    context.read<InvitePeopleCubit>().sendInvite(
      email: email,
      relationship: _selectedRelationship,
      subject: l.invitePeopleEmailSubject(
        _relationshipLabel(_selectedRelationship, l),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authService = context.read<AuthService>();
    final isLoggedIn = authService.isLoggedIn();

    return Scaffold(
      appBar: AppBar(title: Text(l.invitePeopleTitle)),
      body: BlocListener<InvitePeopleCubit, InvitePeopleState>(
        listener: (context, state) {
          if (state is InvitePeopleSuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l.invitePeopleSent)));
            context.pop();
          }
          if (state is InvitePeopleError) {
            final message = state.code == InvitePeopleErrorCode.sendFailed
                ? l.invitePeopleError
                : state.message ?? '';
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l.invitePeopleEmailLabel,
                  border: const OutlineInputBorder(),
                ),
                enabled: isLoggedIn,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<InviteRelationship>(
                initialValue: _selectedRelationship,
                decoration: InputDecoration(
                  labelText: l.invitePeopleRelationshipLabel,
                  border: const OutlineInputBorder(),
                ),
                items: InviteRelationship.values.map((rel) {
                  return DropdownMenuItem(
                    value: rel,
                    child: Text(_relationshipLabel(rel, l)),
                  );
                }).toList(),
                onChanged: isLoggedIn
                    ? (value) {
                        if (value != null) {
                          setState(() => _selectedRelationship = value);
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 32),
              BlocBuilder<InvitePeopleCubit, InvitePeopleState>(
                builder: (context, state) {
                  final isLoading = state is InvitePeopleLoading;
                  return FilledButton(
                    onPressed: isLoading || !isLoggedIn
                        ? null
                        : () => _handleSendInvite(l),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l.invitePeopleSend),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
