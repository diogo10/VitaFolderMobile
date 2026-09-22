import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/router/app_routes.dart';
import 'package:house_mira/core/widgets/sand/google_g_icon.dart';
import 'package:house_mira/core/widgets/sand/sand_brand_mark.dart';
import 'package:house_mira/core/widgets/sand/sand_primary_button.dart';
import 'package:house_mira/core/widgets/sand/sand_social_button.dart';
import 'package:house_mira/core/widgets/sand/sand_text_field.dart';
import 'package:house_mira/features/login/presentation/cubit/sign_up_cubit.dart';
import 'package:house_mira/features/login/presentation/cubit/sign_up_state.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/sand_palette.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      await context.read<SignUpCubit>().signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: SandPalette.sand50,
      appBar: AppBar(
        backgroundColor: SandPalette.sand50,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: SandPalette.sand600),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: BlocConsumer<SignUpCubit, SignUpState>(
            listener: (context, state) {
              if (state is SignUpSuccess) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l.signUpSuccessMessage)));
                context.go(AppRoutes.home);
              }
              if (state is SignUpError) {
                final message = state.code == SignUpErrorCode.unexpected
                    ? l.signUpUnexpectedError
                    : state.message ?? '';
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              }
            },
            builder: (context, state) {
              final isLoading = state is SignUpLoading;

              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: SandBrandMark(),
                    ),
                    const SizedBox(height: 32),
                    Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                        children: [
                          TextSpan(
                            text: l.signUpTitleTop,
                            style: const TextStyle(color: SandPalette.sand700),
                          ),
                          const TextSpan(text: '\n'),
                          TextSpan(
                            text: l.signUpTitleBottom,
                            style: const TextStyle(color: SandPalette.sand500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.signUpSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: SandPalette.sand400,
                        height: 1.625,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SandSocialButton(
                      icon: const GoogleGIcon(),
                      label: l.signUpContinueGoogle,
                      onTap: isLoading
                          ? null
                          : () async {
                              await context
                                  .read<SignUpCubit>()
                                  .signInWithGoogle();
                            },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: SandPalette.sand200),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            l.signUpOrEmail.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: SandPalette.sand400,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.5,
                                ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: SandPalette.sand200),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SandLabeledField(
                      controller: _nameController,
                      label: l.signUpNameLabel,
                      hint: l.signUpNamePlaceholder,
                      prefixIcon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l.signUpNameRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SandLabeledField(
                      controller: _emailController,
                      label: l.signUpEmailLabel,
                      hint: l.signUpEmailPlaceholder,
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l.signUpEmailRequired;
                        }
                        if (!value.contains('@')) {
                          return l.signUpEmailInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SandLabeledField(
                      controller: _passwordController,
                      label: l.signUpPasswordLabel,
                      hint: l.signUpPasswordPlaceholder,
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: true,
                      helperText: l.signUpPasswordHint,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l.signUpPasswordRequired;
                        }
                        if (value.length < 8) {
                          return l.signUpPasswordTooShort;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SandPrimaryButton(
                      label: l.signUpCreateAccount,
                      icon: Icons.arrow_circle_right_rounded,
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _onSignUp,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.account),
                        child: Text.rich(
                          TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: SandPalette.sand400),
                            children: [
                              TextSpan(text: l.signUpAlreadyHaveAccount),
                              const TextSpan(text: ' '),
                              TextSpan(
                                text: l.signUpSignInLink,
                                style: const TextStyle(
                                  color: SandPalette.sand600,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  decorationColor: SandPalette.sand600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: SandPalette.sand400,
                                fontSize: 10,
                                height: 1.5,
                              ),
                          children: [
                            TextSpan(text: l.signUpAgreePrefix),
                            TextSpan(
                              text: l.signUpTermsOfService,
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(text: l.signUpAgreeAnd),
                            TextSpan(
                              text: l.signUpPrivacyPolicy,
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(text: l.signUpAgreeSuffix),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
