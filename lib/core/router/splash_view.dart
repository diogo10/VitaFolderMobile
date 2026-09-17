import 'package:flutter/material.dart';

/// Transient loading screen shown while the authentication state is being
/// determined (session recovery on app restart).
///
/// The router redirects here until [AuthStateNotifier.isInitialized] becomes
/// true, which prevents a flash of unauthenticated content (FOUNC).
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
