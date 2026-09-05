import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartExpenseApp());

    // Verify that the app starts (we have a Home tab in the bottom nav).
    expect(find.text('Home'), findsOneWidget);
  });
}
