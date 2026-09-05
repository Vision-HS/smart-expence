import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense/main.dart';

void main() {
  testWidgets('Check for overflow on small screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320 * 3, 480 * 3);
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(const SmartExpenseApp());
    await tester.pumpAndSettle();
    
    final exceptions = tester.takeException();
    if (exceptions != null) {
      if (exceptions is Iterable) {
        for (final e in exceptions) {
          if (e.toString().contains('overflow')) {
            fail('Overflow found: $e');
          }
        }
      } else if (exceptions.toString().contains('overflow')) {
        fail('Overflow found: $exceptions');
      }
    }
  });
}
