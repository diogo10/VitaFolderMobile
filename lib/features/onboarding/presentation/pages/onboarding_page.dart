import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/observability/app_logger.dart';
import 'package:house_mira/core/router/app_routes.dart';
import 'package:house_mira/features/onboarding/data/datasource/onboarding_local_datasource.dart';
import 'package:house_mira/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:house_mira/generated/app_localizations.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({required this.datasource, super.key, this.logger});

  /// Completion-flag store, constructor-injected (no GetIt in widgets).
  /// Resolved by name at the router composition root.
  final OnboardingLocalDatasource datasource;

  /// Observability sink for completion failures, injected at the router
  /// seam (GetIt `appLogger`, Crashlytics-backed in production). The
  /// `?? AppLogger()` fallback below is intentional for widget tests that
  /// build [OnboardingPage] directly without DI: it keeps the failure
  /// visible via debugPrint plus the retry SnackBar instead of throwing
  /// on a missing registration.
  final AppLogger? logger;

  Future<void> _handleComplete(BuildContext context) async {
    try {
      await datasource.completeOnboarding();
    } on Object catch (error, stackTrace) {
      (logger ?? AppLogger()).warning(
        'completeOnboarding failed',
        tag: 'onboarding',
        error: error,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.onboardingCompleteFailed,
            ),
          ),
        );
      }
      return;
    }
    if (context.mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingView(onComplete: () => _handleComplete(context));
  }
}
