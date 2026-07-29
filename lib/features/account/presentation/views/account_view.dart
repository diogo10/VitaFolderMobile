import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/features/account/presentation/views/no_account_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_cubit.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_cubit.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_state.dart';
import 'package:vita_folder_mobile/features/account/presentation/views/account_loaded_widget.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/people_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';

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
    return BlocConsumer<AccountCubit, AccountState>(
      listener: (context, state) {
        if (state is AccountLogoutSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You have been signed out.")),
          );

           // Reaload tabs 
           context.read<HomeCubit>().getHomeData();
           context.read<PeopleCubit>().getPeople();
           context.read<RemindersCubit>().getReminders();
        }

        if (state is LoginFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login failed. Please try again.")),
          );
        }
      },
      builder: (context, state) {
        if (state is AccountLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is NoAccount || state is AccountLogoutSuccess || state is LoginFailed) {
          return const NoAccountView();
        }

        if (state is AccountLoaded) {
          return const AccountLoadedWidget();
        }

        return const SizedBox.shrink();
      },
    );
  }
}
