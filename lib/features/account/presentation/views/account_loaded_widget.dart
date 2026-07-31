import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_cubit.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_state.dart';
import 'package:vita_folder_mobile/features/account/presentation/views/account_header_widget.dart';
import 'package:vita_folder_mobile/features/account/presentation/views/account_settings_widget.dart';

class AccountLoadedWidget extends StatelessWidget {
  const AccountLoadedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.select<AccountCubit, AccountState>((cubit) => cubit.state);

    if (state is! AccountLoaded) {
      return const SizedBox.shrink();
    }

    final loadedState = state;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AccountHeaderWidget(
              userName: loadedState.userName,
              email: loadedState.email,
            ),
            AccountSettingsWidget(
              familyCode: loadedState.familyCode, 
              isAdmin: loadedState.myRole == "admin",
            ),
          ],
        ),
      ),
    );
  }
}
