import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense/core/services/sms_parser_service.dart';

void main() {
  group('SmsParserService Tests', () {
    final parser = SmsParserService.instance;
    final now = DateTime.now().millisecondsSinceEpoch;

    test('Parses HDFC Bank debit card SMS correctly', () {
      const smsBody =
          'Sent Rs.450.00 from HDFC Bank A/C **1234 to SWIGGY on 11-09-24 via UPI. Ref 42551234.';
      const sender = 'VM-HDFCBK';

      final result = parser.parseSms(
        body: smsBody,
        sender: sender,
        timestamp: now,
      );

      expect(result, isNotNull);
      expect(result!.amount, 450.0);
      expect(result.merchant, 'Swiggy');
      expect(result.suggestedCategory, 'Food');
      expect(result.bankSource, 'HDFC Bank');
      expect(result.paymentMode, 'UPI');
    });

    test('Parses SBI Bank debit SMS correctly', () {
      const smsBody =
          'Your a/c no. XXXXXXX1234 is debited for Rs 1200.00 on 10-09-2024 14:20:10 by transfer to Uber India. Avl Bal Rs 24500.50 - SBI';
      const sender = 'AX-SBIINB';

      final result = parser.parseSms(
        body: smsBody,
        sender: sender,
        timestamp: now,
      );

      expect(result, isNotNull);
      expect(result!.amount, 1200.0);
      expect(result.merchant, 'Uber');
      expect(result.suggestedCategory, 'Travel');
      expect(result.bankSource, 'State Bank of India');
    });

    test('Parses ICICI Bank Shopping SMS correctly', () {
      const smsBody =
          'Your ICICI Bank Credit Card XX4002 has been spent for INR 2,499.00 at AMAZON INDIA on 09-SEP-24.';
      const sender = 'AD-ICICIB';

      final result = parser.parseSms(
        body: smsBody,
        sender: sender,
        timestamp: now,
      );

      expect(result, isNotNull);
      expect(result!.amount, 2499.0);
      expect(result.merchant, 'Amazon');
      expect(result.suggestedCategory, 'Shopping');
      expect(result.bankSource, 'ICICI Bank');
      expect(result.paymentMode, 'Card');
    });

    test('Parses Axis Bank Zomato payment SMS with slash-hyphen amount', () {
      const smsBody =
          'Rs. 350/- debited from Axis Bank A/c no. XX9999 towards Zomato on 14-09-24 via UPI.';
      const sender = 'AX-AXISBK';

      final result = parser.parseSms(
        body: smsBody,
        sender: sender,
        timestamp: now,
      );

      expect(result, isNotNull);
      expect(result!.amount, 350.0);
      expect(result.merchant, 'Zomato');
      expect(result.suggestedCategory, 'Food');
      expect(result.bankSource, 'Axis Bank');
    });

    test('Parses IDFC FIRST Bank credit SMS correctly without false Cred merchant', () {
      const smsBody =
          'Your A/C XXXXX049213 is credited with INR 1.00 on 15/09/26 12:30. Your new balance is INR 25,003.00. Team IDFC FIRST Bank';
      const sender = 'VM-IDFCFB';

      final result = parser.parseSms(
        body: smsBody,
        sender: sender,
        timestamp: now,
      );

      expect(result, isNotNull);
      expect(result!.amount, 1.0);
      expect(result.isIncome, true);
      expect(result.isCredit, true);
      expect(result.merchant, isNot('Cred'));
      expect(result.bankSource, 'IDFC FIRST Bank');
    });

    test('Parses Salary Credit SMS properly as Income', () {
      const smsBody =
          'Salary of INR 75,000.00 credited to your A/c XX4321 from TECH CORP on 31-AUG-24. Avail bal INR 90,000.00';
      const sender = 'AD-HDFCBK';

      final result = parser.parseSms(
        body: smsBody,
        sender: sender,
        timestamp: now,
      );

      expect(result, isNotNull);
      expect(result!.amount, 75000.0);
      expect(result.isIncome, true);
      expect(result.suggestedCategory, 'Salary');
    });

    test('Distinguishes actual CRED app debit payment from credited SMS', () {
      const smsBody =
          'Rs. 5,000.00 debited from A/C XX1234 on 12-09-24 towards CRED club. Ref 987654';
      const sender = 'VM-HDFCBK';

      final result = parser.parseSms(
        body: smsBody,
        sender: sender,
        timestamp: now,
      );

      expect(result, isNotNull);
      expect(result!.amount, 5000.0);
      expect(result.isIncome, false);
      expect(result.merchant.toLowerCase(), 'cred');
    });

    test('Skips promotional or security OTP messages', () {
      const otpSms =
          'Your OTP for logging into netbanking is 849201. Do not share this OTP with anyone. Valid for 10 mins.';
      const sender = 'VK-HDFCBK';

      final result = parser.parseSms(
        body: otpSms,
        sender: sender,
        timestamp: now,
      );

      expect(result, isNull);
    });
  });
}
