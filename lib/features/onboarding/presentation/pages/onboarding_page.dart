import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vita_folder_mobile/core/injections/service_locator.dart';
import 'package:vita_folder_mobile/features/onboarding/data/datasource/onboarding_local_datasource.dart';
import 'package:vita_folder_mobile/features/onboarding/presentation/views/onboarding_view.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  Future<void> _handleComplete(BuildContext context) async {
    final datasource = slInstance<OnboardingLocalDatasource>(
      instanceName: 'onboardingLocalDatasource',
    );
    await datasource.completeOnboarding();
    if (context.mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingView(onComplete: () => _handleComplete(context));
  }
}
