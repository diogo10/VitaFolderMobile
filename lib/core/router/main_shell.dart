import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

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
      body: navigationShell,
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
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
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
