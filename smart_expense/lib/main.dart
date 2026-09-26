import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/main_wrapper_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  final bool isLoggedIn = await AuthService.instance.isUserAuthenticated();
  runApp(SmartExpenseApp(isLoggedIn: isLoggedIn));
}

class SmartExpenseApp extends StatelessWidget {
  final bool isLoggedIn;
  const SmartExpenseApp({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Expense',
      theme: AppTheme.lightTheme,
      home: isLoggedIn ? const MainWrapperScreen() : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
