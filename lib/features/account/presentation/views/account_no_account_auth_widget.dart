import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';
import 'package:vita_folder_mobile/theme/theme_extensions.dart';

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
    final onSurface = context.colorScheme.onSurface;
    final surface = context.colorScheme.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AccountNoAccountSocialButton(
          icon: Icons.g_mobiledata,
          label: l.accountNoAccountContinueGoogle,
        ),
        const SizedBox(height: 14),
        _AccountNoAccountSocialButton(
          icon: Icons.apple,
          label: l.accountNoAccountContinueApple,
        ),
        const SizedBox(height: 20),
        Text(
          l.accountNoAccountOrEmail,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: onSurface.withValues(alpha: 0.68),
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: l.accountNoAccountEmailLabel,
                  prefixIcon: const Icon(Icons.mail_outline),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: l.accountNoAccountPasswordLabel,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onForgotPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: context.colorScheme.primary,
                    textStyle: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  child: Text(l.accountNoAccountForgotPassword),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: isLoading ? null : onSignIn,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l.accountNoAccountSignIn),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountNoAccountSocialButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AccountNoAccountSocialButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: context.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: context.colorScheme.onSurface,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
