import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense/core/services/notification_parser_service.dart';

void main() {
  group('NotificationParserService UPI & Banking Tests', () {
    final parser = NotificationParserService.instance;
    final now = DateTime.now().millisecondsSinceEpoch;

    test('Google Pay debit payment parsed correctly', () {
      final res = parser.parseNotification(
        packageName: 'com.google.android.apps.nbu.paisa.user',
        title: 'Google Pay',
        text: 'You paid ₹250.00 to Chai Point using HDFC Bank A/C',
        timestamp: now,
      );

      expect(res, isNotNull);
      expect(res!.amount, 250.0);
      expect(res.isIncome, false);
      expect(res.merchant, contains('Chai Point'));
      expect(res.suggestedCategory, 'Food');
      expect(res.bankSource, 'Google Pay');
      expect(res.paymentMode, 'UPI');
    });

    test('Google Pay credit payment parsed correctly', () {
      final res = parser.parseNotification(
        packageName: 'com.google.android.apps.nbu.paisa.user',
        title: 'Google Pay',
        text: '₹1,500.00 received from Anand Kumar',
        timestamp: now,
      );

      expect(res, isNotNull);
      expect(res!.amount, 1500.0);
      expect(res.isIncome, true);
      expect(res.merchant, contains('Anand Kumar'));
      expect(res.bankSource, 'Google Pay');
    });

    test('PhonePe debit payment parsed correctly', () {
      final res = parser.parseNotification(
        packageName: 'com.phonepe.app',
        title: 'Payment Successful',
        text: '₹120 paid to Tea Post.',
        timestamp: now,
      );

      expect(res, isNotNull);
      expect(res!.amount, 120.0);
      expect(res.isIncome, false);
      expect(res.merchant, contains('Tea Post'));
      expect(res.suggestedCategory, 'Food');
      expect(res.bankSource, 'PhonePe');
    });

    test('PhonePe credit payment parsed correctly', () {
      final res = parser.parseNotification(
        packageName: 'com.phonepe.app',
        title: 'PhonePe',
        text: 'Received ₹500 from Dad',
        timestamp: now,
      );

      expect(res, isNotNull);
      expect(res!.amount, 500.0);
      expect(res.isIncome, true);
      expect(res.merchant, contains('Dad'));
      expect(res.bankSource, 'PhonePe');
    });

    test('Paytm debit payment parsed correctly', () {
      final res = parser.parseNotification(
        packageName: 'net.one97.paytm',
        title: 'Paytm',
        text: 'Paid ₹80 successfully to Cafe Coffee',
        timestamp: now,
      );

      expect(res, isNotNull);
      expect(res!.amount, 80.0);
      expect(res.isIncome, false);
      expect(res.merchant, contains('Cafe Coffee'));
      expect(res.suggestedCategory, 'Food');
      expect(res.bankSource, 'Paytm');
    });

    test('Paytm credit payment parsed correctly', () {
      final res = parser.parseNotification(
        packageName: 'net.one97.paytm',
        title: 'Paytm',
        text: 'Money received: ₹350 from Rahul Sharma',
        timestamp: now,
      );

      expect(res, isNotNull);
      expect(res!.amount, 350.0);
      expect(res.isIncome, true);
      expect(res.merchant, contains('Rahul Sharma'));
      expect(res.bankSource, 'Paytm');
    });

    test('CRED bill payment parsed correctly', () {
      final res = parser.parseNotification(
        packageName: 'com.dreamplug.androidapp',
        title: 'CRED',
        text: 'Paid ₹2,500 bill using CRED UPI',
        timestamp: now,
      );

      expect(res, isNotNull);
      expect(res!.amount, 2500.0);
      expect(res.isIncome, false);
      expect(res.suggestedCategory, 'Bills');
      expect(res.bankSource, 'CRED');
    });

    test('Bank app notification parsed correctly', () {
      final res = parser.parseNotification(
        packageName: 'com.snapwork.hdfc',
        title: 'HDFC Bank Alert',
        text: 'Rs. 450.00 debited towards Swiggy on 19-Sep-26',
        timestamp: now,
      );

      expect(res, isNotNull);
      expect(res!.amount, 450.0);
      expect(res.isIncome, false);
      expect(res.merchant, 'Swiggy');
      expect(res.suggestedCategory, 'Food');
      expect(res.bankSource, 'HDFC Bank');
    });

    test('Promotional loan offer notification is rejected', () {
      final res = parser.parseNotification(
        packageName: 'net.one97.paytm',
        title: 'Pre-Approved Loan',
        text: 'Congratulations! Pre-approved personal loan of Rs. 5,00,000. Apply now.',
        timestamp: now,
      );

      expect(res, isNull);
    });

    test('Cashback discount promotion is rejected', () {
      final res = parser.parseNotification(
        packageName: 'com.phonepe.app',
        title: 'Special Offer',
        text: 'Get cashback up to ₹50 on your next mobile recharge! Use code WIN50.',
        timestamp: now,
      );

      expect(res, isNull);
    });
  });
}
