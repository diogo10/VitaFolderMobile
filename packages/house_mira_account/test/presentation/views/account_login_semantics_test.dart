import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira_account/presentation/views/account_no_account_auth_widget.dart';
import 'package:house_mira_core/generated/app_localizations.dart';

/// Pins the semantics identifiers the device e2e suite locates by
/// (`e2e/tests/login.e2e.ts`). Renaming or dropping one fails there on a real
/// emulator with a much slower feedback loop, so it is pinned here first.
void main() {
  testWidgets('login form exposes the e2e identifiers', (tester) async {
    final handle = tester.ensureSemantics();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    addTearDown(emailController.dispose);
    addTearDown(passwordController.dispose);
    try {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AccountNoAccountAuthWidget(
              emailController: emailController,
              passwordController: passwordController,
              onSignIn: () {},
              onGoogleSignIn: () {},
              onAppleSignIn: () {},
              onForgotPassword: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      final email = find.bySemanticsIdentifier('account-email-field');
      final password = find.bySemanticsIdentifier('account-password-field');
      final signIn = find.bySemanticsIdentifier('account-sign-in-button');

      expect(email, findsOneWidget);
      expect(password, findsOneWidget);
      expect(signIn, findsOneWidget);

      expect(
        tester
            .getSemantics(email)
            .getSemanticsData()
            .flagsCollection
            .isTextField,
        isTrue,
      );
      expect(
        tester
            .getSemantics(password)
            .getSemanticsData()
            .flagsCollection
            .isTextField,
        isTrue,
      );
      expect(
        tester.getSemantics(signIn).getSemanticsData().flagsCollection.isButton,
        isTrue,
      );
    } finally {
      handle.dispose();
    }
  });
}
