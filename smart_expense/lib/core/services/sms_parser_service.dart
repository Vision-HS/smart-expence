import 'dart:async';
import 'package:flutter/services.dart';
import '../../features/expenses/models/pending_sms_model.dart';
import '../../features/expenses/repositories/transaction_repository.dart';

class SmsParserService {
  static final SmsParserService instance = SmsParserService._init();

  static const MethodChannel _methodChannel =
      MethodChannel('com.example.smart_expense/sms_channel');
  static const EventChannel _eventChannel =
      EventChannel('com.example.smart_expense/sms_stream');

  StreamController<PendingSmsModel>? _streamController;
  StreamSubscription? _nativeSubscription;

  SmsParserService._init();

  /// Check if SMS permissions are granted
  Future<bool> checkPermissions() async {
    try {
      final bool granted =
          await _methodChannel.invokeMethod('checkSmsPermissions') ?? false;
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Request runtime SMS permissions from user
  Future<bool> requestPermissions() async {
    try {
      final bool granted =
          await _methodChannel.invokeMethod('requestSmsPermissions') ?? false;
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Real-time stream of parsed incoming banking SMS messages
  Stream<PendingSmsModel> get onIncomingSms {
    if (_streamController == null) {
      _streamController = StreamController<PendingSmsModel>.broadcast();
      _startNativeListening();
    }
    return _streamController!.stream;
  }

  void _startNativeListening() {
    _nativeSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) async {
        if (event is Map) {
          final sender = event['sender']?.toString() ?? '';
          final body = event['body']?.toString() ?? '';
          final timestamp = (event['timestamp'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch;

          final parsed = parseSms(
            body: body,
            sender: sender,
            timestamp: timestamp,
          );

          if (parsed != null) {
            // Save to pending SQLite queue
            await TransactionRepository.instance.insertPendingSms(parsed);
            _streamController?.add(parsed);
          }
        }
      },
      onError: (err) {
        // Stream error handler
      },
    );
  }

  /// Scan existing SMS inbox and parse transactions into SQLite
  Future<int> syncInboxMessages({int limit = 60}) async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        final granted = await requestPermissions();
        if (!granted) return 0;
      }

      final List<dynamic>? rawMessages = await _methodChannel.invokeMethod(
        'readInboxSms',
        {'limit': limit},
      );

      if (rawMessages == null || rawMessages.isEmpty) return 0;

      final existingList =
          await TransactionRepository.instance.getPendingSms();
      final existingKeys = existingList
          .map((e) => '${e.amount}_${e.merchant}_${e.timeString}')
          .toSet();

      int newlyAdded = 0;

      for (final raw in rawMessages) {
        if (raw is Map) {
          final sender = raw['sender']?.toString() ?? '';
          final body = raw['body']?.toString() ?? '';
          final timestamp = (raw['timestamp'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch;

          final parsed = parseSms(
            body: body,
            sender: sender,
            timestamp: timestamp,
          );

          if (parsed != null) {
            final key = '${parsed.amount}_${parsed.merchant}_${parsed.timeString}';
            if (!existingKeys.contains(key)) {
              await TransactionRepository.instance.insertPendingSms(parsed);
              existingKeys.add(key);
              newlyAdded++;
            }
          }
        }
      }

      return newlyAdded;
    } catch (_) {
      return 0;
    }
  }

  /// Robust Regex Parser for Indian Banks & UPI Messages
  PendingSmsModel? parseSms({
    required String body,
    required String sender,
    required int timestamp,
  }) {
    final lowerBody = body.toLowerCase();

    // 1. Skip non-financial SMS (e.g. Pure OTPs without debit/credit)
    final isOtp = lowerBody.contains('otp') ||
        lowerBody.contains('verification code') ||
        lowerBody.contains('one time password') ||
        lowerBody.contains('do not share');

    final isFinancial = lowerBody.contains('debited') ||
        lowerBody.contains('spent') ||
        lowerBody.contains('paid') ||
        lowerBody.contains('withdrawn') ||
        lowerBody.contains('credited') ||
        lowerBody.contains('transferred') ||
        lowerBody.contains('txn') ||
        lowerBody.contains('vpa') ||
        lowerBody.contains('upi');

    if (isOtp && !isFinancial) return null;
    if (!isFinancial) return null;

    // 2. Extract Amount
    double? amount;
    final amountRegex = RegExp(
      r'(?:(?:Rs\.?|INR|\u20B9)\s*([\d,]+(?:\.\d{1,2})?)|(?:debited|spent|paid|withdrawn|credited|transferred)\s+(?:by|for|of)?\s*(?:Rs\.?|INR|\u20B9)?\s*([\d,]+(?:\.\d{1,2})?))',
      caseSensitive: false,
    );

    final amountMatch = amountRegex.firstMatch(body);
    if (amountMatch != null) {
      final strVal = (amountMatch.group(1) ?? amountMatch.group(2))
          ?.replaceAll(',', '')
          .trim();
      if (strVal != null) {
        amount = double.tryParse(strVal);
      }
    }

    if (amount == null || amount <= 0) return null;

    // 3. Extract Merchant / Payee
    String merchant = _extractMerchant(body, lowerBody);

    // 4. Extract Bank Source
    String bankSource = _extractBankSource(sender, body);

    // 5. Categorize
    String category = _categorize(merchant, lowerBody);

    // 6. Payment Mode (UPI vs Card vs NetBanking)
    String paymentMode = 'UPI';
    if (lowerBody.contains('card') || lowerBody.contains('credit card') || lowerBody.contains('debit card')) {
      paymentMode = 'Card';
    } else if (lowerBody.contains('netbanking') || lowerBody.contains('imps') || lowerBody.contains('neft')) {
      paymentMode = 'NetBanking';
    }

    // 7. Format Date / Time
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final timeString =
        '${_formatTwoDigits(dateTime.hour)}:${_formatTwoDigits(dateTime.minute)}';
    final timeAgo = _calculateTimeAgo(dateTime);

    final id = 'sms_${timestamp}_${amount.toInt()}';

    return PendingSmsModel(
      id: id,
      merchant: merchant,
      amount: amount,
      paymentMode: paymentMode,
      timeString: timeString,
      timeAgo: timeAgo,
      suggestedCategory: category,
      bankSource: bankSource,
      isSecondCard: paymentMode == 'Card',
    );
  }

  String _extractMerchant(String body, String lowerBody) {
    // Look for: at <Merchant> or to <Merchant> or info: <Merchant> or towards <Merchant>
    final merchantRegex = RegExp(
      r'(?:at|to|info\s*:?|towards|vpa|paid to)\s+([A-Za-z0-9\s*.\-_&]+?)(?:\s+on|\s+ref|\s+upi|\s+avl|\s+bal|\s+via|\s+thru|\.|\,|$)',
      caseSensitive: false,
    );

    final match = merchantRegex.firstMatch(body);
    if (match != null) {
      String m = match.group(1)?.trim() ?? '';
      // Clean up common words
      m = m.replaceAll(RegExp(r'^(the|a|an)\s+', caseSensitive: false), '');
      if (m.isNotEmpty && m.length <= 30 && !m.toLowerCase().contains('account') && !m.toLowerCase().contains('card')) {
        return _titleCase(m);
      }
    }

    // Fallbacks based on famous apps / keywords
    if (lowerBody.contains('swiggy')) return 'Swiggy';
    if (lowerBody.contains('zomato')) return 'Zomato';
    if (lowerBody.contains('uber')) return 'Uber';
    if (lowerBody.contains('ola')) return 'Ola Cabs';
    if (lowerBody.contains('amazon')) return 'Amazon';
    if (lowerBody.contains('flipkart')) return 'Flipkart';
    if (lowerBody.contains('blinkit')) return 'Blinkit';
    if (lowerBody.contains('zepto')) return 'Zepto';
    if (lowerBody.contains('paytm')) return 'Paytm Payment';
    if (lowerBody.contains('google pay') || lowerBody.contains('gpay')) return 'Google Pay';
    if (lowerBody.contains('phonepe')) return 'PhonePe';

    return 'Merchant / UPI';
  }

  String _extractBankSource(String sender, String body) {
    final upperSender = sender.toUpperCase();
    final upperBody = body.toUpperCase();

    if (upperSender.contains('HDFC') || upperBody.contains('HDFC')) return 'HDFC Bank';
    if (upperSender.contains('SBI') || upperBody.contains('SBI')) return 'SBI Bank';
    if (upperSender.contains('ICICI') || upperBody.contains('ICICI')) return 'ICICI Bank';
    if (upperSender.contains('AXIS') || upperBody.contains('AXIS')) return 'Axis Bank';
    if (upperSender.contains('KOTAK') || upperBody.contains('KOTAK')) return 'Kotak Mahindra';
    if (upperSender.contains('PNB') || upperBody.contains('PUNJAB')) return 'PNB';
    if (upperSender.contains('BOB') || upperBody.contains('BARODA')) return 'Bank of Baroda';
    if (upperSender.contains('PAYTM') || upperBody.contains('PAYTM')) return 'Paytm Bank';
    if (upperSender.contains('IDFC') || upperBody.contains('IDFC')) return 'IDFC First';
    if (upperSender.contains('CANARA') || upperBody.contains('CANARA')) return 'Canara Bank';
    if (upperSender.contains('UNION') || upperBody.contains('UNION BANK')) return 'Union Bank';
    if (upperSender.contains('YES') || upperBody.contains('YES BANK')) return 'Yes Bank';

    return 'Bank Alert';
  }

  String _categorize(String merchant, String lowerBody) {
    final text = '${merchant.toLowerCase()} $lowerBody';

    if (text.contains('swiggy') ||
        text.contains('zomato') ||
        text.contains('mcdonald') ||
        text.contains('domino') ||
        text.contains('kfc') ||
        text.contains('starbucks') ||
        text.contains('cafe') ||
        text.contains('restaurant') ||
        text.contains('bakery') ||
        text.contains('food') ||
        text.contains('pizza') ||
        text.contains('burger') ||
        text.contains('tea') ||
        text.contains('coffee')) {
      return 'Food';
    }

    if (text.contains('uber') ||
        text.contains('ola') ||
        text.contains('rapido') ||
        text.contains('irctc') ||
        text.contains('petrol') ||
        text.contains('fuel') ||
        text.contains('shell') ||
        text.contains('hpcl') ||
        text.contains('bpcl') ||
        text.contains('ioc') ||
        text.contains('flight') ||
        text.contains('indigo') ||
        text.contains('makemytrip') ||
        text.contains('metro')) {
      return 'Travel';
    }

    if (text.contains('amazon') ||
        text.contains('flipkart') ||
        text.contains('myntra') ||
        text.contains('ajio') ||
        text.contains('meesho') ||
        text.contains('nykaa') ||
        text.contains('croma') ||
        text.contains('reliance') ||
        text.contains('zudio') ||
        text.contains('dmart') ||
        text.contains('blinkit') ||
        text.contains('zepto') ||
        text.contains('mall') ||
        text.contains('store')) {
      return 'Shopping';
    }

    if (text.contains('airtel') ||
        text.contains('jio') ||
        text.contains('vi ') ||
        text.contains('electricity') ||
        text.contains('bescom') ||
        text.contains('broadband') ||
        text.contains('wifi') ||
        text.contains('dth') ||
        text.contains('recharge') ||
        text.contains('billdesk') ||
        text.contains('gas')) {
      return 'Bills';
    }

    if (text.contains('netflix') ||
        text.contains('spotify') ||
        text.contains('hotstar') ||
        text.contains('prime video') ||
        text.contains('bookmyshow') ||
        text.contains('cinema') ||
        text.contains('pvr') ||
        text.contains('inox')) {
      return 'Entertainment';
    }

    if (text.contains('apollo') ||
        text.contains('pharmacy') ||
        text.contains('1mg') ||
        text.contains('practo') ||
        text.contains('hospital') ||
        text.contains('clinic') ||
        text.contains('medplus') ||
        text.contains('dr.')) {
      return 'Health';
    }

    return 'General';
  }

  String _formatTwoDigits(int n) => n.toString().padLeft(2, '0');

  String _calculateTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  String _titleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  void dispose() {
    _nativeSubscription?.cancel();
    _streamController?.close();
    _streamController = null;
  }
}
