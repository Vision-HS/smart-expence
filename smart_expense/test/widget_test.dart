import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense/main.dart';

void main() {
  testWidgets('App starts with LoginScreen and displays key elements', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartExpenseApp());

    expect(find.text('Smart Expense'), findsWidgets);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Unlock Smart Expense'), findsOneWidget);
    expect(find.text('Phone & OTP'), findsOneWidget);
    expect(find.text('Use Fingerprint / Face Unlock'), findsOneWidget);
  });
}
