import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense/main.dart';

void main() {
  testWidgets('App starts with LoginScreen and displays key elements', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartExpenseApp());
    await tester.pumpAndSettle();

    expect(find.text('Smart Expense'), findsWidgets);
    expect(find.text('Create 4-Digit PIN'), findsOneWidget);
    expect(find.text('Step 1 of 2: Enter 4 digits'), findsOneWidget);
  });
}
