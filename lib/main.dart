import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/analytics/analytics_service.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/auth/auth_state_notifier.dart';
import 'package:house_mira/core/config/app_config.dart';
import 'package:house_mira/core/config/firebase_options_provider.dart';
import 'package:house_mira/core/functions/edget_functions.dart';
import 'package:house_mira/core/injections/service_locator.dart';
import 'package:house_mira/core/observability/app_logger.dart';
import 'package:house_mira/core/observability/crash_reporter.dart';
import 'package:house_mira/core/observability/performance_tracer.dart';
import 'package:house_mira/core/router/app_router.dart';
import 'package:house_mira/core/router/app_routes.dart';
import 'package:house_mira/features/account/application/notification_permission_service.dart';
import 'package:house_mira/features/account/presentation/cubit/account_cubit.dart';
import 'package:house_mira/features/account/presentation/cubit/manage_profile_cubit.dart';
import 'package:house_mira/features/account/presentation/cubit/notification_settings_cubit.dart';
import 'package:house_mira/features/home/presentation/cubit/home_cubit.dart';
import 'package:house_mira/features/login/presentation/cubit/sign_up_cubit.dart';
import 'package:house_mira/features/onboarding/data/datasource/onboarding_local_datasource.dart';
import 'package:house_mira/features/people/presentation/cubit/family_settings_cubit.dart';
import 'package:house_mira/features/people/presentation/cubit/invite_people_cubit.dart';
import 'package:house_mira/features/people/presentation/cubit/people_cubit.dart';
import 'package:house_mira/features/reminders/application/reminder_notification_service.dart';
import 'package:house_mira/features/reminders/presentation/cubit/create_reminder_cubit.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Backend credentials come from --dart-define / env/<flavor>.json
  // (see README "Environments & secrets"). Missing or invalid values
  // throw StateError here so the app never runs against the wrong backend.
  final config = AppConfig.fromEnvironment();

  // Firebase first: Crashlytics handlers must be installed before any other
  // async init so startup failures become visible instead of silent.
  await Firebase.initializeApp(options: firebaseOptionsFor(config.flavor));
  FirebaseCrashReporter.installGlobalHandlers();

  final crashReporter = FirebaseCrashReporter();
  final logger = AppLogger(crashReporter: crashReporter);
  final tracer = FirebasePerformanceTracer();

  try {
    await tracer.trace('startup-supabase-init', (trace) async {
      await Supabase.initialize(
        url: config.supabaseUrl,
        publishableKey: config.supabasePublishableKey,
      );
      await trace.putAttribute('flavor', config.flavor.name);
    });
  } on Object catch (error, stackTrace) {
    logger.error(
      'supabase init failed',
      tag: 'startup',
      context: {'flavor': config.flavor.name},
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }

  final serviceLocator = ServiceLocator();
  await serviceLocator.init(
    crashReporter: crashReporter,
    logger: logger,
    tracer: tracer,
  );

  try {
    await slInstance<IReminderNotificationService>(
      instanceName: 'reminderNotificationService',
    ).init();
  } on Object catch (error, stackTrace) {
    // Notifications are best-effort; never block app startup — but report
    // the failure instead of swallowing it silently.
    logger.warning(
      'notification init failed',
      tag: 'startup',
      error: error,
      stackTrace: stackTrace,
    );
  }

  final analyticsService = slInstance<AnalyticsService>(
    instanceName: 'analyticsService',
  );
  try {
    await analyticsService.initialize();
  } on Object catch (error, stackTrace) {
    logger.warning(
      'analytics init failed',
      tag: 'startup',
      error: error,
      stackTrace: stackTrace,
    );
  }

  final datasource = slInstance<OnboardingLocalDatasource>(
    instanceName: 'onboardingLocalDatasource',
  );
  final onboardingCompleted = await datasource.isOnboardingCompleted();

  runApp(
    MultiBlocProvider(
      providers: [
        Provider(
          create: (_) => slInstance<AuthService>(instanceName: 'authService'),
        ),
        BlocProvider(
          create: (_) =>
              slInstance<RemindersCubit>(instanceName: 'remindersCubit'),
        ),
        BlocProvider(
          create: (_) => slInstance<CreateReminderCubit>(
            instanceName: 'createReminderCubit',
          ),
        ),
        BlocProvider(
          create: (_) => slInstance<HomeCubit>(instanceName: 'homeCubit'),
        ),
        BlocProvider(
          create: (_) => slInstance<PeopleCubit>(instanceName: 'peopleCubit'),
        ),
        BlocProvider(
          create: (_) => slInstance<AccountCubit>(instanceName: 'accountCubit'),
        ),
        BlocProvider(
          create: (_) => slInstance<ManageProfileCubit>(
            instanceName: 'manageProfileCubit',
          ),
        ),
        BlocProvider(
          create: (_) => slInstance<NotificationSettingsCubit>(
            instanceName: 'notificationSettingsCubit',
          ),
        ),
        BlocProvider(
          create: (_) => slInstance<FamilySettingsCubit>(
            instanceName: 'familySettingsCubit',
          ),
        ),
        BlocProvider(
          create: (_) =>
              SignUpCubit(slInstance<AuthService>(instanceName: 'authService')),
        ),
        BlocProvider(
          create: (_) => InvitePeopleCubit(
            edgetFunctions: slInstance<EdgetFunctions>(
              instanceName: 'edgetFunctions',
            ),
          ),
        ),
      ],
      child: MyApp(onboardingCompleted: onboardingCompleted),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    required this.onboardingCompleted,
    super.key,
    this.authStateNotifier,
    this.notificationService,
    this.initialLocation,
  });
  final bool onboardingCompleted;
  final AuthStateNotifier? authStateNotifier;

  /// Testing seam (and deep-link entry): overrides the service resolved
  /// from GetIt for notification tap/launch routing.
  final IReminderNotificationService? notificationService;

  /// Testing seam (and OS deep-link entry): overrides the router's initial
  /// location, e.g. an `/invite/<code>` App Link on cold start.
  final String? initialLocation;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _notificationPermissionRequested = false;
  late final AuthStateNotifier _authStateNotifier;
  bool _ownsAuthStateNotifier = false;
  late final GoRouter _router;
  StreamSubscription<String?>? _notificationTapSubscription;

  @override
  void initState() {
    super.initState();
    final external = widget.authStateNotifier;
    if (external != null) {
      _authStateNotifier = external;
    } else {
      // Session persistence is handled by Supabase.initialize; this
      // subscription replays the recovered initial session and keeps the
      // router synchronized with every later auth transition.
      _authStateNotifier = AuthStateNotifier.fromSupabase(
        Supabase.instance.client,
        crashReporter: _optional<CrashReporter>('crashReporter'),
        logger: _optional<AppLogger>('appLogger'),
        tracer: _optional<PerformanceTracer>('performanceTracer'),
      );
      _ownsAuthStateNotifier = true;
    }
    _syncCrashUserId();
    _authStateNotifier.addListener(_syncCrashUserId);
    final analyticsService = slInstance<AnalyticsService>(
      instanceName: 'analyticsService',
    );
    _router = createRouter(
      onboardingCompleted: widget.onboardingCompleted,
      authStateNotifier: _authStateNotifier,
      observers: [analyticsService.observer],
      initialLocation: widget.initialLocation,
    );
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Independent best-effort tasks: cold-start notification routing
      // must not wait for the permission dialog to resolve.
      unawaited(_requestNotificationPermission());
      unawaited(_handleNotificationLaunch());
    });
    _subscribeNotificationTaps();
  }

  /// Notification service override for tests, else the GetIt singleton.
  IReminderNotificationService? get _notificationService =>
      widget.notificationService ?? _optionalNotificationService();

  static IReminderNotificationService? _optionalNotificationService() {
    return _optional<IReminderNotificationService>(
      'reminderNotificationService',
    );
  }

  static T? _optional<T extends Object>(String instanceName) {
    if (slInstance.isRegistered<T>(instanceName: instanceName)) {
      return slInstance<T>(instanceName: instanceName);
    }
    return null;
  }

  AppLogger get _logger => _optional<AppLogger>('appLogger') ?? AppLogger();

  PerformanceTracer get _tracer =>
      _optional<PerformanceTracer>('performanceTracer') ??
      NoOpPerformanceTracer();

  /// Keeps crash reports attributable: every auth transition mirrors the
  /// current user id into Crashlytics. Best-effort only.
  void _syncCrashUserId() {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      unawaited(
        _optional<CrashReporter>(
          'crashReporter',
        )?.setUserId(userId ?? _authStateNotifier.session?.user.id),
      );
    } on Object catch (_) {
      // Identity sync is best-effort.
    }
  }

  /// Routes tapped notifications to the reminders list. Best-effort only:
  /// a missing service or dead context never crashes the app.
  ///
  /// Payloads carry the tapped reminder id; with no reminder-detail screen
  /// the list is the target — see [notificationLocationFor].
  void _subscribeNotificationTaps() {
    final service = _notificationService;
    if (service == null) return;
    try {
      _notificationTapSubscription = service.onNotificationTap.listen((
        payload,
      ) {
        if (payload == null || payload.isEmpty) return;
        if (!mounted) return;
        _router.go(notificationLocationFor(payload));
      });
    } on Object catch (error, stackTrace) {
      // Notifications are best-effort.
      _logger.warning(
        'notification tap subscription failed',
        tag: 'notifications',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Cold start via a notification also lands on the reminders list.
  Future<void> _handleNotificationLaunch() async {
    try {
      final payload = await _notificationService?.getLaunchPayload();
      if (payload == null || payload.isEmpty) return;
      if (!mounted) return;
      _router.go(notificationLocationFor(payload));
    } on Object catch (error, stackTrace) {
      // Notifications are best-effort.
      _logger.warning(
        'notification launch routing failed',
        tag: 'notifications',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await _requestNotificationPermission();
      await _resyncNotifications();
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (_notificationPermissionRequested) return;
    _notificationPermissionRequested = true;
    await NotificationPermissionService().requestNotificationPermission();
  }

  /// Re-arms alarms wiped while the app was away (force-stop, reboot,
  /// time-zone change). Best-effort: never disrupts the UI. Traced so
  /// silent alarm loss shows up in Performance, failures in Crashlytics.
  Future<void> _resyncNotifications() async {
    try {
      await _tracer.trace('reminder-resync-resume', (trace) async {
        await slInstance<RemindersCubit>(
          instanceName: 'remindersCubit',
        ).resyncNotifications();
        await trace.putAttribute('trigger', 'app_resume');
      });
    } on Object catch (error, stackTrace) {
      // Notifications are best-effort.
      _logger.warning(
        'resume resync failed',
        tag: 'reminder-resync',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authStateNotifier.removeListener(_syncCrashUserId);
    unawaited(_notificationTapSubscription?.cancel());
    if (_ownsAuthStateNotifier) {
      _authStateNotifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HouseMira',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
