import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/people_cubit.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/people_state.dart';
import 'package:vita_folder_mobile/features/people/presentation/widgets/people_empty_widget.dart';
import 'package:vita_folder_mobile/features/people/presentation/widgets/people_loaded_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class PeopleView extends StatefulWidget {
  const PeopleView({super.key});

  @override
  State<PeopleView> createState() => _PeopleViewState();
}

class _PeopleViewState extends State<PeopleView> {
  final _familyNameController = TextEditingController();

  void _onCreateFamilyPressed() {
    showDialog(
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
            onPressed: () {
              final name = _familyNameController.text.trim();
              if (name.isNotEmpty) {
                context.read<PeopleCubit>().createFamily(name: name);
                _familyNameController.clear();
                Navigator.of(dialogContext).pop();
              }
            },
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    context.read<PeopleCubit>().getPeople();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PeopleCubit, PeopleState>(
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

        if (state is PeopleEmpty) {
          return PeopleEmptyWidget(
            onCreateFamilyPressed: _onCreateFamilyPressed,
          );
        }

        if (state is! PeopleLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return PeopleLoadedWidget(
          people: state.people,
          inviteCode: state.inviteCode,
          familyName: state.familyName,
        );
      },
    );
  }
}
