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
          return PeopleEmptyWidget();
        }

        if (state is! PeopleLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return PeopleLoadedWidget(people: state.people);
      },
    );
  }
}
