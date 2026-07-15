import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_cubit.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_state.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/home_view_empty.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/home_view_success.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().getHomeData();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is HomeError) {
          return const Center(child: Text('Something went wrong.'));
        }

        if (state is HomeEmpty) {
          return const HomeViewEmpty();
        }

        if (state is HomeLoaded) {
          return HomeViewSuccess(data: state.data);
        }

        return const SizedBox.shrink();
      },
    );
  }
}
