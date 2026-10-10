import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/router/app_routes.dart';
import 'package:house_mira/features/onboarding/data/datasource/onboarding_local_datasource.dart';
import 'package:house_mira/features/onboarding/presentation/views/onboarding_view.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({required this.datasource, super.key});

  /// Completion-flag store, constructor-injected (no GetIt in widgets).
  /// Resolved by name at the router composition root.
  final OnboardingLocalDatasource datasource;

  Future<void> _handleComplete(BuildContext context) async {
    await datasource.completeOnboarding();
    if (context.mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingView(onComplete: () => _handleComplete(context));
  }
}
