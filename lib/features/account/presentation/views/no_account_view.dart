import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira/features/account/presentation/cubit/account_cubit.dart';
import 'package:house_mira/features/account/presentation/cubit/account_state.dart';
import 'package:house_mira/features/account/presentation/views/account_no_account_auth_widget.dart';
import 'package:house_mira/features/account/presentation/views/account_no_account_footer_widget.dart';
import 'package:house_mira/features/account/presentation/views/account_no_account_header_widget.dart';
import 'package:house_mira/theme/sand_palette.dart';

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
      backgroundColor: SandPalette.sand50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: AccountNoAccountHeaderWidget(),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: BlocBuilder<AccountCubit, AccountState>(
                  builder: (context, state) {
                    return AccountNoAccountAuthWidget(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      isLoading: state is AccountLoading,
                      onSignIn: () async {
                        await context.read<AccountCubit>().signIn(
                          _emailController.text,
                          _passwordController.text,
                        );
                      },
                      onGoogleSignIn: () async {
                        await context.read<AccountCubit>().signInWithGoogle();
                      },
                      onForgotPassword: () async {
                        await context.read<AccountCubit>().forgotPassword(
                          _emailController.text,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: AccountNoAccountFooterWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
