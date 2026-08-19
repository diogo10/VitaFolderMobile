import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vita_folder_mobile/features/account/presentation/views/google_g_icon.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';
import 'package:vita_folder_mobile/theme/sand_palette.dart';

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
        _AccountNoAccountSocialButton(
          icon: const GoogleGIcon(),
          label: l.accountNoAccountContinueGoogle,
        ),
        const SizedBox(height: 12),
        _AccountNoAccountSocialButton(
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
                style: const TextStyle(
                  color: SandPalette.sand400,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Expanded(child: Divider(color: SandPalette.sand200)),
          ],
        ),
        const SizedBox(height: 20),
        _AccountNoAccountFieldLabel(
          label: l.accountNoAccountEmailLabel,
          trailing: null,
        ),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: SandPalette.sand600, fontSize: 14),
          decoration: _inputDecoration(
            hint: l.accountNoAccountEmailPlaceholder,
            prefixIcon: Icons.mail_outline_rounded,
          ),
        ),
        const SizedBox(height: 16),
        _AccountNoAccountFieldLabel(
          label: l.accountNoAccountPasswordLabel,
          trailing: TextButton(
            onPressed: onForgotPassword,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l.accountNoAccountForgotPassword,
              style: const TextStyle(
                color: SandPalette.sand400,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        _PasswordField(controller: passwordController),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: SandPalette.sand500.withValues(alpha: 0.30),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: SandPalette.sand500,
              foregroundColor: SandPalette.sand50,
              disabledBackgroundColor: SandPalette.sand300,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: SandPalette.sand50,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.login, size: 18),
                      const SizedBox(width: 8),
                      Text(l.accountNoAccountSignIn),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: () => context.push('/sign-up'),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: SandPalette.sand400,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(text: l.accountNoAccountNewToApp),
                  TextSpan(text: ' '),
                  TextSpan(
                    text: l.accountNoAccountCreateFreeAccount,
                    style: const TextStyle(
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

InputDecoration _inputDecoration({
  required String hint,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: SandPalette.sand300, fontSize: 14),
    prefixIcon: Icon(prefixIcon, size: 18, color: SandPalette.sand400),
    suffixIcon: suffixIcon,
    prefixIconConstraints: const BoxConstraints(minWidth: 48),
    suffixIconConstraints: const BoxConstraints(minWidth: 48),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: SandPalette.sand200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: SandPalette.sand200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: SandPalette.sand500, width: 1.5),
    ),
  );
}

class _AccountNoAccountFieldLabel extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const _AccountNoAccountFieldLabel({
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: SandPalette.sand500,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;

  const _PasswordField({required this.controller});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return TextField(
      controller: widget.controller,
      obscureText: _obscured,
      style: const TextStyle(color: SandPalette.sand600, fontSize: 14),
      decoration: _inputDecoration(
        hint: l.accountNoAccountPasswordPlaceholder,
        prefixIcon: Icons.lock_outline_rounded,
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscured = !_obscured),
          icon: Icon(
            _obscured ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            size: 18,
            color: SandPalette.sand300,
          ),
        ),
      ),
    );
  }
}

class _AccountNoAccountSocialButton extends StatelessWidget {
  final Widget icon;
  final String label;

  const _AccountNoAccountSocialButton({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SandPalette.sand200),
        boxShadow: [
          BoxShadow(
            color: SandPalette.sand500.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 20, height: 20, child: Center(child: icon)),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: SandPalette.sand600,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
