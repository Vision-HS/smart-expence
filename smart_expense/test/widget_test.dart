import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense/main.dart';

void main() {
  testWidgets('App starts with LoginScreen and displays key elements', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartExpenseApp());
    await tester.pumpAndSettle();

    expect(find.text('Smart Expense'), findsWidgets);
    expect(find.text('Phone OTP'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Get OTP'), findsOneWidget);
  });
}
