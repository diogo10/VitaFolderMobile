import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/core/injections/service_locator.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_cubit.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/home_view.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/screens/reminders_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final serviceLocator = ServiceLocator();
  await serviceLocator.init();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => slInstance<RemindersCubit>(instanceName: 'remindersCubit'),
        ),
        BlocProvider(
          create: (_) => slInstance<HomeCubit>(instanceName: 'homeCubit'),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitaFolder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainView(),
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

  static const List<Widget> _tabViews = [
    HomeView(),
    RemindersView(),
    Center(child: Text('Favorites Content')),
    Center(child: Text('Profile Content')),
  ];

  static const List<String> _tabLabels = [
    'Home',
    'Reminders',
    'Favorites',
    'Profile',
  ];

  static const List<IconData> _tabIcons = [
    Icons.home,
    Icons.notifications,
    Icons.favorite,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabViews[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
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