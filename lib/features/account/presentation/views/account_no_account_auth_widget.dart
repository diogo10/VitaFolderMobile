import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/widgets/sand/google_g_icon.dart';
import 'package:house_mira/core/widgets/sand/sand_primary_button.dart';
import 'package:house_mira/core/widgets/sand/sand_social_button.dart';
import 'package:house_mira/core/widgets/sand/sand_text_field.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/sand_palette.dart';

class AccountNoAccountAuthWidget extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSignIn;
  final VoidCallback onForgotPassword;
  final bool isLoading;

  const AccountNoAccountAuthWidget({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onSignIn,
    required this.onForgotPassword,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SandSocialButton(
          icon: const GoogleGIcon(),
          label: l.accountNoAccountContinueGoogle,
        ),
        const SizedBox(height: 12),
        SandSocialButton(
          icon: const Icon(Icons.apple, size: 18, color: SandPalette.sand700),
          label: l.accountNoAccountContinueApple,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Divider(color: SandPalette.sand200)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                l.accountNoAccountOrEmail,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: SandPalette.sand400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Expanded(child: Divider(color: SandPalette.sand200)),
          ],
        ),
        const SizedBox(height: 20),
        SandLabeledField(
          controller: emailController,
          label: l.accountNoAccountEmailLabel,
          hint: l.accountNoAccountEmailPlaceholder,
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        SandLabeledField(
          controller: passwordController,
          label: l.accountNoAccountPasswordLabel,
          hint: l.accountNoAccountPasswordPlaceholder,
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: true,
          labelTrailing: TextButton(
            onPressed: onForgotPassword,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l.accountNoAccountForgotPassword,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: SandPalette.sand400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SandPrimaryButton(
          label: l.accountNoAccountSignIn,
          icon: Icons.login,
          isLoading: isLoading,
          onPressed: onSignIn,
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: () => context.push('/sign-up'),
            child: Text.rich(
              TextSpan(
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: SandPalette.sand400),
                children: [
                  TextSpan(text: l.accountNoAccountNewToApp),
                  TextSpan(text: ' '),
                  TextSpan(
                    text: l.accountNoAccountCreateFreeAccount,
                    style: TextStyle(
                      color: SandPalette.sand600,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: SandPalette.sand600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
