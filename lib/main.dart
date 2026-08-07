import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/core/functions/edget_functions.dart';
import 'package:vita_folder_mobile/core/injections/service_locator.dart';
import 'package:vita_folder_mobile/core/router/app_router.dart';
import 'package:vita_folder_mobile/features/account/application/notification_permission_service.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_cubit.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/manage_profile_cubit.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/notification_settings_cubit.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_cubit.dart';
import 'package:vita_folder_mobile/features/login/presentation/cubit/sign_up_cubit.dart';
import 'package:vita_folder_mobile/features/onboarding/data/datasource/onboarding_local_datasource.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/invite_people_cubit.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/people_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/create_reminder_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';
import 'package:vita_folder_mobile/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://jheqalwrnztavzxjsdcj.supabase.co',
    publishableKey: 'sb_publishable_CD4bacDoKowxJ4QLLn7y-A_0ftYBnHb',
  );

  final serviceLocator = ServiceLocator();
  await serviceLocator.init();

  final datasource = slInstance<OnboardingLocalDatasource>(
    instanceName: 'onboardingLocalDatasource',
  );
  final onboardingCompleted = await datasource.isOnboardingCompleted();

  runApp(
    MultiBlocProvider(
      providers: [
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
          create: (_) => SignUpCubit(
            slInstance<AuthService>(instanceName: 'authService'),
          ),
        ),
        BlocProvider(
          create: (_) => InvitePeopleCubit(
            edgetFunctions: slInstance<EdgetFunctions>(instanceName: 'edgetFunctions'),
          ),
        )
      ],
      child: MyApp(onboardingCompleted: onboardingCompleted),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool onboardingCompleted;

  const MyApp({super.key, required this.onboardingCompleted});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _notificationPermissionRequested = false;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VitaFolder',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: createRouter(onboardingCompleted: widget.onboardingCompleted),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
