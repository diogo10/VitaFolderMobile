import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:house_mira/core/analytics/analytics_service.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/auth/auth_state_notifier.dart';
import 'package:house_mira/core/functions/edget_functions.dart';
import 'package:house_mira/core/injections/service_locator.dart';
import 'package:house_mira/core/router/app_router.dart';
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
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://jheqalwrnztavzxjsdcj.supabase.co',
    publishableKey: 'sb_publishable_CD4bacDoKowxJ4QLLn7y-A_0ftYBnHb',
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final serviceLocator = ServiceLocator();
  await serviceLocator.init();

  try {
    await slInstance<IReminderNotificationService>(
      instanceName: 'reminderNotificationService',
    ).init();
  } catch (_) {
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
  final bool onboardingCompleted;
  final AuthStateNotifier? authStateNotifier;

  const MyApp({
    super.key,
    required this.onboardingCompleted,
    this.authStateNotifier,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _notificationPermissionRequested = false;
  late final AuthStateNotifier _authStateNotifier;
  bool _ownsAuthStateNotifier = false;

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
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermission();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _requestNotificationPermission();
    }
  }

  void _requestNotificationPermission() {
    if (_notificationPermissionRequested) return;
    _notificationPermissionRequested = true;
    NotificationPermissionService().requestNotificationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsAuthStateNotifier) {
      _authStateNotifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsService = slInstance<AnalyticsService>(
      instanceName: 'analyticsService',
    );
    return MaterialApp.router(
      title: 'HouseMira',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: createRouter(
        onboardingCompleted: widget.onboardingCompleted,
        authStateNotifier: _authStateNotifier,
        observers: [analyticsService.observer],
      ),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
