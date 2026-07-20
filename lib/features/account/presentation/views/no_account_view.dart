import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_cubit.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_state.dart';
import 'package:vita_folder_mobile/features/account/presentation/views/account_no_account_auth_widget.dart';
import 'package:vita_folder_mobile/features/account/presentation/views/account_no_account_footer_widget.dart';
import 'package:vita_folder_mobile/features/account/presentation/views/account_no_account_header_widget.dart';
import 'package:vita_folder_mobile/theme/theme_extensions.dart';

class NoAccountView extends StatefulWidget {
  const NoAccountView({super.key});

  @override
  State<NoAccountView> createState() => _NoAccountViewState();
}

class _NoAccountViewState extends State<NoAccountView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AccountNoAccountHeaderWidget(),
              const SizedBox(height: 28),
              BlocBuilder<AccountCubit, AccountState>(
                builder: (context, state) {
                  return AccountNoAccountAuthWidget(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    isLoading: state is AccountLoading,
                    onSignIn: () {
                      context.read<AccountCubit>().signIn(
                        _emailController.text,
                        _passwordController.text,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 28),
              const AccountNoAccountFooterWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
