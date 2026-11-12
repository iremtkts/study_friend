import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'home_screen.dart';
import 'study_screen.dart';
import 'tutor_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selected = 0;
  final List<int> _pageVersions = List<int>.filled(5, 0);

  List<Widget> get _pages => [
    HomeScreen(key: ValueKey('home-${_pageVersions[0]}')),
    StudyScreen(key: ValueKey('study-${_pageVersions[1]}')),
    TutorScreen(key: ValueKey('tutor-${_pageVersions[2]}')),
    ProgressScreen(key: ValueKey('progress-${_pageVersions[3]}')),
    ProfileScreen(key: ValueKey('profile-${_pageVersions[4]}')),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: IndexedStack(index: _selected, children: _pages),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selected,
      onDestinationSelected: (index) {
        if (index == _selected) {
          return;
        }
        setState(() {
          _selected = index;
          _pageVersions[index]++;
        });
      },
      backgroundColor: Colors.white,
      indicatorColor: AppColors.lavender.withValues(alpha: .48),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Ana sayfa',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded),
          label: 'Çalış',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome),
          label: 'Fiko',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights),
          label: 'İlerleme',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    ),
  );
}
