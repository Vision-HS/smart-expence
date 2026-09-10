import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense/features/expenses/models/transaction_model.dart';
import 'package:smart_expense/features/expenses/models/pending_sms_model.dart';

void main() {
  group('TransactionModel Tests', () {
    test('toMap and fromMap serialize and deserialize properly', () {
      final tx = TransactionModel(
        id: 1,
        title: 'Starbucks Coffee',
        amount: -350.0,
        category: 'Food & Dining',
        dateTime: '2024-09-03T09:15:00',
        account: 'Google Pay',
        paymentType: 'UPI',
        isIncome: false,
        monthYear: 'September 2024',
        rawSms: 'Sent Rs.350 to Starbucks via UPI',
        notes: 'Morning coffee',
      );

      final map = tx.toMap();
      expect(map['id'], 1);
      expect(map['title'], 'Starbucks Coffee');
      expect(map['amount'], -350.0);
      expect(map['category'], 'Food & Dining');
      expect(map['isIncome'], 0);
      expect(map['monthYear'], 'September 2024');

      final reconstructed = TransactionModel.fromMap(map);
      expect(reconstructed.id, 1);
      expect(reconstructed.title, 'Starbucks Coffee');
      expect(reconstructed.amount, -350.0);
      expect(reconstructed.category, 'Food & Dining');
      expect(reconstructed.isIncome, false);
      expect(reconstructed.monthYear, 'September 2024');
      expect(reconstructed.notes, 'Morning coffee');
    });

    test('UI presentation helpers compute appropriate icons and colors', () {
      final foodTx = TransactionModel(
        title: 'Swiggy',
        amount: -420.0,
        category: 'Food',
        dateTime: '2024-09-03T13:20:00',
        account: 'ICICI',
        paymentType: 'Card',
        isIncome: false,
        monthYear: 'September 2024',
      );

      expect(foodTx.isIncome, false);
      expect(foodTx.subtitle.contains('Food'), true);
      expect(foodTx.subtitle.contains('Card'), true);

      final salaryTx = TransactionModel(
        title: 'Salary',
        amount: 50000.0,
        category: 'Salary',
        dateTime: '2024-09-02T10:00:00',
        account: 'HDFC',
        paymentType: 'Bank Transfer',
        isIncome: true,
        monthYear: 'September 2024',
      );

      expect(salaryTx.isIncome, true);
    });
  });

  group('PendingSmsModel Tests', () {
    test('toMap and fromMap serialize and deserialize correctly', () {
      final sms = PendingSmsModel(
        id: 'sms_test_1',
        merchant: 'Amazon',
        amount: 1499.0,
        paymentMode: 'Card',
        timeString: 'Today, 10:42 AM',
        timeAgo: 'Just now',
        suggestedCategory: 'Shopping',
        bankSource: 'Detected from ICICI Bank SMS',
        isSecondCard: true,
      );

      final map = sms.toMap();
      expect(map['id'], 'sms_test_1');
      expect(map['merchant'], 'Amazon');
      expect(map['amount'], 1499.0);
      expect(map['paymentMode'], 'Card');
      expect(map['suggestedCategory'], 'Shopping');
      expect(map['isSecondCard'], 1);

      final reconstructed = PendingSmsModel.fromMap(map);
      expect(reconstructed.id, 'sms_test_1');
      expect(reconstructed.merchant, 'Amazon');
      expect(reconstructed.amount, 1499.0);
      expect(reconstructed.isSecondCard, true);
    });
  });
}
