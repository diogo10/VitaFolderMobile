import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/invite_people_cubit.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/invite_people_state.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

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
        return 'Self';
      case InviteRelationship.spouse:
        return 'Spouse';
      case InviteRelationship.child:
        return 'Child';
      case InviteRelationship.parent:
        return 'Parent';
      case InviteRelationship.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite People'),
      ),
      body: BlocListener<InvitePeopleCubit, InvitePeopleState>(
        listener: (context, state) {
          if (state is InvitePeopleSuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(content: Text('Invite sent!')));
            context.pop();
          }
          if (state is InvitePeopleError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
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
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<InviteRelationship>(
                initialValue: _selectedRelationship,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  border: OutlineInputBorder(),
                ),
                items: InviteRelationship.values.map((rel) {
                  return DropdownMenuItem(
                    value: rel,
                    child: Text(_relationshipLabel(rel, l)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRelationship = value);
                  }
                },
              ),
              const SizedBox(height: 32),
              BlocBuilder<InvitePeopleCubit, InvitePeopleState>(
                builder: (context, state) {
                  final isLoading = state is InvitePeopleLoading;
                  return FilledButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            final email = _emailController.text.trim();
                            if (email.isEmpty) return;
                            context.read<InvitePeopleCubit>().sendInvite(
                                  email: email,
                                  relationship: _selectedRelationship,
                                );
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send Invite'),
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