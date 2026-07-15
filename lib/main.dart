import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/core/injections/service_locator.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_cubit.dart';
import 'package:vita_folder_mobile/features/account/presentation/views/account_view.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_cubit.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/home_view.dart';
import 'package:vita_folder_mobile/features/onboarding/data/datasource/onboarding_local_datasource.dart';
import 'package:vita_folder_mobile/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:vita_folder_mobile/features/people/presentation/cubit/people_cubit.dart';
import 'package:vita_folder_mobile/features/people/presentation/views/people_view.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/screens/reminders_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final serviceLocator = ServiceLocator();
  await serviceLocator.init();

  final datasource =
      slInstance<OnboardingLocalDatasource>(instanceName: 'onboardingLocalDatasource');
  final onboardingCompleted = await datasource.isOnboardingCompleted();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => slInstance<RemindersCubit>(instanceName: 'remindersCubit'),
        ),
        BlocProvider(
          create: (_) => slInstance<HomeCubit>(instanceName: 'homeCubit'),
        ),
        BlocProvider(
          create: (_) => slInstance<PeopleCubit>(instanceName: 'peopleCubit'),
        ),
        BlocProvider(
          create: (_) => AccountCubit(),
        ),
      ],
      child: MyApp(showOnboarding: !onboardingCompleted),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;

  const MyApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitaFolder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: showOnboarding ? const _OnboardingWrapper() : const MainView(),
    );
  }
}

class _OnboardingWrapper extends StatelessWidget {
  const _OnboardingWrapper();

  Future<void> _completeOnboarding(BuildContext context) async {
    final datasource =
        slInstance<OnboardingLocalDatasource>(instanceName: 'onboardingLocalDatasource');
    await datasource.completeOnboarding();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingView(
      onComplete: () => _completeOnboarding(context),
    );
  }
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int _selectedIndex = 0;

  final List<Widget> _tabViews = const [
    HomeView(),
    RemindersView(),
    PeopleView(),
    AccountView(),
  ];

  static const List<String> _tabLabels = [
    'Home',
    'Reminders',
    'People',
    'Account',
  ];

  static const List<IconData> _tabIcons = [
    Icons.home,
    Icons.notifications,
    Icons.people,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabViews,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: List.generate(
          _tabLabels.length,
          (i) => BottomNavigationBarItem(
            icon: Icon(_tabIcons[i]),
            label: _tabLabels[i],
          ),
        ),
      ),
    );
  }
}