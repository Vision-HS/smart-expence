import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense/core/theme/app_theme.dart';
import 'package:smart_expense/features/settings/screens/profile_screen.dart';

void main() {
  testWidgets('ProfileScreen renders all header, metrics, and security controls', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ProfileScreen(),
      ),
    );

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Hiren'), findsWidgets);
    expect(find.text('Local Ledger Member since Aug 2024'), findsOneWidget);
    expect(find.text('Offline First Account'), findsOneWidget);
    expect(find.text('Phone (SMS Sync)'), findsOneWidget);
    expect(find.text('+91 98765 24012'), findsOneWidget);
    expect(find.text('Quick PIN'), findsOneWidget);
    expect(find.text('Biometric Unlock'), findsOneWidget);
    expect(find.text('144'), findsOneWidget);
    expect(find.text('2.4 MB'), findsOneWidget);
    expect(find.text('Lock Current Session'), findsOneWidget);
  });
}
