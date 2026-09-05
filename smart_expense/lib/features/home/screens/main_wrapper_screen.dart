import 'package:flutter/material.dart';
import '../../../shared/widgets/bottom_navigation.dart';
import 'home_screen.dart';
import '../../expenses/screens/expenses_screen.dart';
import '../../reports/screens/reports_screen.dart';
import '../../settings/screens/settings_screen.dart';

class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    HomeScreen(
      onViewAllPressed: () {
        setState(() {
          _currentIndex = 1;
        });
      },
    ),
    const ExpensesScreen(),
    const ReportsScreen(),
    SettingsScreen(
      onBack: () {
        setState(() {
          _currentIndex = 0;
        });
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
