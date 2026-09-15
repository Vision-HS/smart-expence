import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/sms_parser_service.dart';
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
  StreamSubscription? _smsSubscription;

  @override
  void initState() {
    super.initState();
    _initSmsAutoSync();
  }

  Future<void> _initSmsAutoSync() async {
    // 1. Listen for real-time incoming SMS alerts
    _smsSubscription = SmsParserService.instance.onIncomingSms.listen((sms) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bank Alert: ₹${sms.amount.toInt()} at ${sms.merchant}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF131B2E),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    // 2. Check if SMS permission is granted and auto-sync inbox
    try {
      final hasPermission = await SmsParserService.instance.checkPermissions();
      if (hasPermission) {
        await SmsParserService.instance.syncInboxMessages(limit: 150);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _smsSubscription?.cancel();
    super.dispose();
  }

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
