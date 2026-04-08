import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'history_analytics_screen.dart';
import 'environment_comparison_screen.dart';
import 'recommendations_screen.dart';
import 'settings_screen.dart';

/// Root scaffold with persistent bottom navigation bar.
/// Uses IndexedStack so each tab keeps its scroll state.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const _tabs = [
    DashboardScreen(),
    HistoryAnalyticsScreen(),
    EnvironmentComparisonScreen(),
    RecommendationsScreen(),
    SettingsScreen(),
  ];

  static const _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard_rounded),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history_rounded),
      activeIcon: Icon(Icons.history_rounded),
      label: 'History',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.compare_arrows_rounded),
      activeIcon: Icon(Icons.compare_arrows_rounded),
      label: 'Compare',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.lightbulb_outline_rounded),
      activeIcon: Icon(Icons.lightbulb_rounded),
      label: 'Tips',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.tune_rounded),
      activeIcon: Icon(Icons.tune_rounded),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.cardBorder)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: _items,
        ),
      ),
    );
  }
}
