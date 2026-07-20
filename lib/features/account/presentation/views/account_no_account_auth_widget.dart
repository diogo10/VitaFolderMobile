import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/theme/theme_extensions.dart';

class AccountNoAccountAuthWidget extends StatelessWidget {
  const AccountNoAccountAuthWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = context.colorScheme.onSurface;
    final surface = context.colorScheme.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AccountNoAccountSocialButton(
          icon: Icons.g_mobiledata,
          label: 'Continue with Google',
        ),
        const SizedBox(height: 14),
        _AccountNoAccountSocialButton(
          icon: Icons.apple,
          label: 'Continue with Apple',
        ),
        const SizedBox(height: 20),
        Text(
          'or sign in with email',
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
                decoration: InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: const Icon(Icons.mail_outline),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: context.colorScheme.primary,
                    textStyle: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Sign In'),
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
