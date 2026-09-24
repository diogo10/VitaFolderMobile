import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/analytics/analytics_service.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/auth/auth_state_notifier.dart';
import 'package:house_mira/core/config/app_config.dart';
import 'package:house_mira/core/config/firebase_options_provider.dart';
import 'package:house_mira/core/injections/service_locator.dart';
import 'package:house_mira/core/observability/app_logger.dart';
import 'package:house_mira/core/observability/crash_reporter.dart';
import 'package:house_mira/core/observability/performance_tracer.dart';
import 'package:house_mira/core/router/app_router.dart';
import 'package:house_mira/core/router/app_routes.dart';
import 'package:house_mira/core/router/tab_refresh_coordinator.dart';
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
    // Cold start stays lean: only the global AuthService (guest gating in
    // every tab) is provided here. Feature cubits are scoped to their
    // StatefulShellBranch / screen route in [createRouter] and first built
    // when that route is visited.
    Provider(
      create: (_) => slInstance<AuthService>(instanceName: 'authService'),
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
    this.refreshCoordinator,
    this.homeCubitFactory,
    this.peopleCubitFactory,
    this.remindersCubitFactory,
    this.accountCubitFactory,
    this.createReminderCubitFactory,
    this.signUpCubitFactory,
    this.invitePeopleCubitFactory,
    this.familySettingsCubitFactory,
    this.notificationSettingsCubitFactory,
    this.manageProfileCubitFactory,
  });
  final bool onboardingCompleted;
  final AuthStateNotifier? authStateNotifier;

  /// Testing seam (and deep-link entry): overrides the service resolved
  /// from GetIt for notification tap/launch routing.
  final IReminderNotificationService? notificationService;

  /// Testing seam (and OS deep-link entry): overrides the router's initial
  /// location, e.g. an `/invite/<code>` App Link on cold start.
  final String? initialLocation;

  /// Cross-tab refresh coordinator shared with [createRouter]. When omitted
  /// a fresh coordinator is created; its reminders callback stays `null`
  /// until the reminders tab builds, so resume-resync never instantiates an
  /// unvisited tab graph.
  final TabRefreshCoordinator? refreshCoordinator;

  /// Testing seams for the route-scoped cubits (see [createRouter] factory
  /// contract): tab factories must return a shared instance, one-shot
  /// factories must return a fresh instance per call.
  final HomeCubit Function()? homeCubitFactory;
  final PeopleCubit Function()? peopleCubitFactory;
  final RemindersCubit Function()? remindersCubitFactory;
  final AccountCubit Function()? accountCubitFactory;
  final CreateReminderCubit Function()? createReminderCubitFactory;
  final SignUpCubit Function()? signUpCubitFactory;
  final InvitePeopleCubit Function()? invitePeopleCubitFactory;
  final FamilySettingsCubit Function()? familySettingsCubitFactory;
  final NotificationSettingsCubit Function()? notificationSettingsCubitFactory;
  final ManageProfileCubit Function()? manageProfileCubitFactory;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _notificationPermissionRequested = false;
  late final AuthStateNotifier _authStateNotifier;
  bool _ownsAuthStateNotifier = false;
  late final GoRouter _router;
  late final TabRefreshCoordinator _refreshCoordinator;
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
    _refreshCoordinator = widget.refreshCoordinator ?? TabRefreshCoordinator();
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
      refreshCoordinator: _refreshCoordinator,
      homeCubitFactory: widget.homeCubitFactory,
      peopleCubitFactory: widget.peopleCubitFactory,
      remindersCubitFactory: widget.remindersCubitFactory,
      accountCubitFactory: widget.accountCubitFactory,
      createReminderCubitFactory: widget.createReminderCubitFactory,
      signUpCubitFactory: widget.signUpCubitFactory,
      invitePeopleCubitFactory: widget.invitePeopleCubitFactory,
      familySettingsCubitFactory: widget.familySettingsCubitFactory,
      notificationSettingsCubitFactory: widget.notificationSettingsCubitFactory,
      manageProfileCubitFactory: widget.manageProfileCubitFactory,
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
  /// time-zone change). Best-effort: never disrupts the UI. Guarded by the
  /// coordinator so an unvisited reminders tab stays unbuilt; failures are
  /// reported instead of swallowed silently.
  Future<void> _resyncNotifications() async {
    final resync = _refreshCoordinator.resyncReminderNotifications;
    if (resync == null) return;
    try {
      await _tracer.trace('reminder-resync-resume', (trace) async {
        resync();
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
