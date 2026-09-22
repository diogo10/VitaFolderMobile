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
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabasePublishableKey,
  );

  await Firebase.initializeApp(options: firebaseOptionsFor(config.flavor));

  final serviceLocator = ServiceLocator();
  await serviceLocator.init();

  try {
    await slInstance<IReminderNotificationService>(
      instanceName: 'reminderNotificationService',
    ).init();
  } on Object catch (_) {
    // Notifications are best-effort; never block app startup.
  }

  final analyticsService = slInstance<AnalyticsService>(
    instanceName: 'analyticsService',
  );
  await analyticsService.initialize();

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
      );
      _ownsAuthStateNotifier = true;
    }
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
    try {
      return slInstance<IReminderNotificationService>(
        instanceName: 'reminderNotificationService',
      );
    } on Object catch (_) {
      return null;
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
    } on Object catch (_) {
      // Notifications are best-effort.
    }
  }

  /// Cold start via a notification also lands on the reminders list.
  Future<void> _handleNotificationLaunch() async {
    try {
      final payload = await _notificationService?.getLaunchPayload();
      if (payload == null || payload.isEmpty) return;
      if (!mounted) return;
      _router.go(notificationLocationFor(payload));
    } on Object catch (_) {
      // Notifications are best-effort.
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
  /// time-zone change). Best-effort: never disrupts the UI.
  Future<void> _resyncNotifications() async {
    try {
      await slInstance<RemindersCubit>(
        instanceName: 'remindersCubit',
      ).resyncNotifications();
    } on Object catch (_) {
      // Notifications are best-effort.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
