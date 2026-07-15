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
import 'package:vita_folder_mobile/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
          create: (_) => slInstance<HomeCubit>(instanceName: 'homeCubit'),
        ),
        BlocProvider(
          create: (_) => slInstance<PeopleCubit>(instanceName: 'peopleCubit'),
        ),
        BlocProvider(create: (_) => AccountCubit()),
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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: showOnboarding ? const _OnboardingWrapper() : const MainView(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _OnboardingWrapper extends StatelessWidget {
  const _OnboardingWrapper();

  Future<void> _completeOnboarding(BuildContext context) async {
    final datasource = slInstance<OnboardingLocalDatasource>(
      instanceName: 'onboardingLocalDatasource',
    );
    await datasource.completeOnboarding();
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainView()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingView(onComplete: () => _completeOnboarding(context));
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
    PeopleView(),
    RemindersView(),
    AccountView(),
  ];

  static const List<String> _tabLabels = [
    'Home',
    'People',
    'Reminders',
    'Account',
  ];

  static const List<IconData> _tabIcons = [
    Icons.home_rounded,
    Icons.groups_rounded,
    Icons.notifications_rounded,
    Icons.account_circle_rounded,
  ];

  Widget _buildNavigationIcon(int index, {required bool isSelected}) {
    final icon = Icon(
      _tabIcons[index],
      size: 24,
      color: isSelected ? Colors.white : const Color(0xFFC2B299),
    );
    final iconWithBadge = index == 2
        ? Badge(
            backgroundColor: const Color(0xFFC2B299),
            smallSize: 7,
            offset: const Offset(5, -3),
            child: icon,
          )
        : icon;

    if (!isSelected) return iconWithBadge;

    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF9A8262),
        shape: BoxShape.circle,
      ),
      child: iconWithBadge,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabViews),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE8DFD3))),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: const Color(0xFFFFFBF7),
          selectedItemColor: const Color(0xFF8B7558),
          unselectedItemColor: const Color(0xFFC2B299),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: List.generate(
            _tabLabels.length,
            (i) => BottomNavigationBarItem(
              icon: _buildNavigationIcon(i, isSelected: false),
              label: _tabLabels[i],
              activeIcon: _buildNavigationIcon(i, isSelected: true),
            ),
          ),
        ),
      ),
    );
  }
}
