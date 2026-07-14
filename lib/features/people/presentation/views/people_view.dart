import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/people_cubit.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/people_state.dart';
import 'package:vita_folder_mobile/features/people/presentation/widgets/person_card_widget.dart';

class PeopleView extends StatefulWidget {
  const PeopleView({super.key});

  @override
  State<PeopleView> createState() => _PeopleViewState();
}

class _PeopleViewState extends State<PeopleView> {
  @override
  void initState() {
    context.read<PeopleCubit>().getPeople();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PeopleCubit, PeopleState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('People'),
          ),
          body: Builder(builder: (_) {
            if (state is PeopleLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (state is PeopleLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<PeopleCubit>().getPeople();
                },
                child: ListView.builder(
                  itemCount: state.people.length,
                  itemBuilder: (_, index) {
                    return PersonCardWidget(
                      key: Key(state.people[index].id.toString()),
                      name: state.people[index].name,
                      email: state.people[index].email,
                      phone: state.people[index].phone,
                      id: state.people[index].id,
                    );
                  },
                ),
              );
            }

            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            );
          }),
        );
      },
    );
  }
}
