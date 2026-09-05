import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/screens/main_wrapper_screen.dart';

void main() {
  runApp(const SmartExpenseApp());
}

class SmartExpenseApp extends StatelessWidget {
  const SmartExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Expense',
      theme: AppTheme.lightTheme,
      home: const MainWrapperScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
