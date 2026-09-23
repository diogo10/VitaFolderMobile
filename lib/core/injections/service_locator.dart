import 'package:get_it/get_it.dart';
import 'package:house_mira/core/analytics/analytics_service.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/auth/google_sign_in_handler.dart';
import 'package:house_mira/core/functions/edget_functions.dart';
import 'package:house_mira/core/injections/account/account_service_locator.dart';
import 'package:house_mira/core/injections/home/home_service_locator.dart';
import 'package:house_mira/core/injections/people/people_service_locator.dart';
import 'package:house_mira/core/injections/reminders/reminder_service_locator.dart';
import 'package:house_mira/core/local_storage/local_storage_datasource.dart';
import 'package:house_mira/core/observability/app_logger.dart';
import 'package:house_mira/core/observability/crash_reporter.dart';
import 'package:house_mira/core/observability/performance_tracer.dart';
import 'package:house_mira/features/onboarding/data/datasource/onboarding_local_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GetIt slInstance = GetIt.instance;

class ServiceLocator {
  Future<void> init() async {
    final crashReporter = FirebaseCrashReporter();
    final logger = AppLogger(crashReporter: crashReporter);
    final tracer = FirebasePerformanceTracer();
    slInstance
      ..registerSingleton<CrashReporter>(
        crashReporter,
        instanceName: 'crashReporter',
      )
      ..registerSingleton<AppLogger>(logger, instanceName: 'appLogger')
      ..registerSingleton<PerformanceTracer>(
        tracer,
        instanceName: 'performanceTracer',
      )
      ..registerSingleton<AnalyticsService>(
        AnalyticsService(crashReporter: crashReporter),
        instanceName: 'analyticsService',
      )
      ..registerSingleton<AuthService>(
        AuthService(
          supabaseClient: Supabase.instance.client,
          googleSignInHandler: GoogleSignInHandler(),
          logger: logger,
          tracer: tracer,
        ),
        instanceName: 'authService',
      )
      ..registerSingleton<EdgetFunctions>(
        EdgetFunctions(logger: logger, tracer: tracer),
        instanceName: 'edgetFunctions',
      )
      ..registerSingleton<OnboardingLocalDatasource>(
        OnboardingLocalDatasource(),
        instanceName: 'onboardingLocalDatasource',
      )
      ..registerSingleton<LocalStorageDatasource>(
        LocalStorageDatasource(),
        instanceName: 'localStorageDatasource',
      );

    PeopleServiceLocator(slInstance).init();

    ReminderServiceLocator(slInstance).init();

    HomeServiceLocator(
      slInstance,
    ).init(slInstance(instanceName: 'authService'));

    AccountServiceLocator(slInstance).init();
  }
}
