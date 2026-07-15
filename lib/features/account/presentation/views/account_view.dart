import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_cubit.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_state.dart';
import 'package:vita_folder_mobile/features/account/presentation/views/account_loaded_widget.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  @override
  void initState() {
    super.initState();
    context.read<AccountCubit>().loadAccount();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountCubit, AccountState>(
      builder: (context, state) {
        if (state is AccountLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AccountLoaded) {
          return const AccountLoadedWidget();
        }

        return const SizedBox.shrink();
      },
    );
  }
}
