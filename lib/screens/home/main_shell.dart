import 'package:flutter/material.dart';
import '../../widgets/navigation/app_bottom_nav.dart';
import 'home_dashboard_screen.dart';
import '../prediction/prediction_screen.dart';
import '../inventory/inventory_screen.dart';
import '../analytics/analytics_screen.dart';
import '../profile/profile_screen.dart';

/// Root shell that hosts the bottom navigation and switches between
/// the five primary tabs while preserving each tab's state.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [
    HomeDashboardScreen(),
    PredictionScreen(),
    InventoryScreen(),
    AnalyticsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: IndexedStack(
          key: ValueKey(_index),
          index: _index,
          children: _screens,
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
