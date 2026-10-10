import 'package:get_it/get_it.dart';
import 'package:house_mira_core/analytics/analytics_service.dart';
import 'package:house_mira_core/auth/auth_service.dart';
import 'package:house_mira_core/auth/google_sign_in_handler.dart';
import 'package:house_mira_core/functions/edget_functions.dart';
import 'package:house_mira_account/account_service_locator.dart';
import 'package:house_mira_home/home_service_locator.dart';
import 'package:house_mira_notes/notes_service_locator.dart';
import 'package:house_mira_paywall/paywall_service_locator.dart';
import 'package:house_mira_people/people_service_locator.dart';
import 'package:house_mira_reminders/reminder_service_locator.dart';
import 'package:house_mira_core/local_storage/local_storage_datasource.dart';
import 'package:house_mira_core/observability/app_logger.dart';
import 'package:house_mira_core/observability/crash_reporter.dart';
import 'package:house_mira_core/observability/performance_tracer.dart';
import 'package:house_mira_core/subscriptions/subscription_service.dart';
import 'package:house_mira_onboarding/data/datasource/onboarding_local_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GetIt slInstance = GetIt.instance;

class ServiceLocator {
  /// Registers core singletons and feature graphs.
  ///
  /// Observability instances are created once in `main` and passed in so
  /// the app and every service share the same [CrashReporter], [AppLogger],
  /// and [PerformanceTracer] instead of each building their own.
  Future<void> init({
    CrashReporter? crashReporter,
    AppLogger? logger,
    PerformanceTracer? tracer,
    SubscriptionService? subscriptionService,
  }) async {
    final effectiveCrashReporter = crashReporter ?? FirebaseCrashReporter();
    final effectiveLogger =
        logger ?? AppLogger(crashReporter: effectiveCrashReporter);
    final effectiveTracer = tracer ?? FirebasePerformanceTracer();
    slInstance
      ..registerSingleton<CrashReporter>(
        effectiveCrashReporter,
        instanceName: 'crashReporter',
      )
      ..registerSingleton<AppLogger>(effectiveLogger, instanceName: 'appLogger')
      ..registerSingleton<PerformanceTracer>(
        effectiveTracer,
        instanceName: 'performanceTracer',
      )
      ..registerSingleton<AnalyticsService>(
        AnalyticsService(crashReporter: effectiveCrashReporter),
        instanceName: 'analyticsService',
      )
      ..registerSingleton<AuthService>(
        AuthService(
          supabaseClient: Supabase.instance.client,
          googleSignInHandler: GoogleSignInHandler(),
          logger: effectiveLogger,
          tracer: effectiveTracer,
        ),
        instanceName: 'authService',
      )
      ..registerSingleton<EdgetFunctions>(
        EdgetFunctions(logger: effectiveLogger, tracer: effectiveTracer),
        instanceName: 'edgetFunctions',
      )
      ..registerSingleton<OnboardingLocalDatasource>(
        OnboardingLocalDatasource(),
        instanceName: 'onboardingLocalDatasource',
      )
      ..registerSingleton<LocalStorageDatasource>(
        LocalStorageDatasource(),
        instanceName: 'localStorageDatasource',
      )
      ..registerSingleton<SubscriptionService>(
        subscriptionService ?? SubscriptionService(logger: effectiveLogger),
        instanceName: 'subscriptionService',
      );

    PeopleServiceLocator(slInstance).init();

    NotesServiceLocator(slInstance).init();

    ReminderServiceLocator(slInstance).init();

    HomeServiceLocator(
      slInstance,
    ).init(slInstance(instanceName: 'authService'));

    AccountServiceLocator(slInstance).init();

    PaywallServiceLocator(slInstance).init();
  }
}
