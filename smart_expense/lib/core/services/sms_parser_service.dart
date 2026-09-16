import 'dart:async';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
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
            await TransactionRepository.instance.insertPendingSms(parsed);
            _streamController?.add(parsed);
          }
        }
      },
      onError: (_) {},
    );
  }

  /// Check and process any SMS messages received while the app was offline/closed
  Future<int> syncBufferedMessages() async {
    try {
      final List<dynamic>? buffered =
          await _methodChannel.invokeMethod('getBufferedSms');
      if (buffered == null || buffered.isEmpty) return 0;

      int count = 0;
      for (final raw in buffered) {
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
            await TransactionRepository.instance.insertPendingSms(parsed);
            _streamController?.add(parsed);
            count++;
          }
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// Scan existing SMS inbox and parse real transactions into SQLite
  Future<int> syncInboxMessages({int limit = 150}) async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        final granted = await requestPermissions();
        if (!granted) return 0;
      }

      // First sync any buffered offline messages
      await syncBufferedMessages();

      final List<dynamic>? rawMessages = await _methodChannel.invokeMethod(
        'readInboxSms',
        {'limit': limit},
      );

      if (rawMessages == null || rawMessages.isEmpty) {
        return 0;
      }

      // Purge any misparsed 'Cred' records so they get correctly categorized as Credit/Bank
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete('pending_sms', where: "merchant = 'Cred'");
      } catch (_) {}

      final existingPending =
          await TransactionRepository.instance.getPendingSms();
      final existingTxns =
          await TransactionRepository.instance.getAllTransactions();

      // Deduplication set using amount, merchant, and isIncome
      final existingKeys = <String>{};
      for (final p in existingPending) {
        existingKeys.add('${p.amount.toInt()}_${p.merchant.toLowerCase()}_${p.isIncome}');
      }
      for (final t in existingTxns) {
        existingKeys.add('${t.amount.abs().toInt()}_${t.title.toLowerCase()}_${t.isIncome}');
      }

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
            final key = '${parsed.amount.toInt()}_${parsed.merchant.toLowerCase()}_${parsed.isIncome}';
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

  /// Comprehensive Regex Parser for Indian Banks & UPI Messages
  PendingSmsModel? parseSms({
    required String body,
    required String sender,
    required int timestamp,
  }) {
    if (body.isEmpty) return null;
    final lowerBody = body.toLowerCase();

    // 1. Skip non-financial SMS (e.g. pure OTPs without transaction indicators)
    final isOtp = lowerBody.contains('otp') ||
        lowerBody.contains('verification code') ||
        lowerBody.contains('one time password') ||
        lowerBody.contains('login code') ||
        lowerBody.contains('secret code');

    final isFinancial = lowerBody.contains('debited') ||
        lowerBody.contains('debit') ||
        lowerBody.contains('spent') ||
        lowerBody.contains('spend') ||
        lowerBody.contains('paid') ||
        lowerBody.contains('pay') ||
        lowerBody.contains('payment') ||
        lowerBody.contains('withdrawn') ||
        lowerBody.contains('withdraw') ||
        lowerBody.contains('credited') ||
        lowerBody.contains('credit') ||
        lowerBody.contains('transferred') ||
        lowerBody.contains('transfer') ||
        lowerBody.contains('sent') ||
        lowerBody.contains('received') ||
        lowerBody.contains('receive') ||
        lowerBody.contains('deducted') ||
        lowerBody.contains('purchase') ||
        lowerBody.contains('txn') ||
        lowerBody.contains('transaction') ||
        lowerBody.contains('vpa') ||
        lowerBody.contains('upi') ||
        lowerBody.contains('imps') ||
        lowerBody.contains('neft') ||
        lowerBody.contains('rtgs') ||
        lowerBody.contains('pos') ||
        lowerBody.contains('auto-debit');

    if (isOtp && !isFinancial) return null;
    if (!isFinancial) return null;

    // 2. Extract Amount
    double? amount;

    // Regex handles:
    // - Rs. 500, Rs.500/-, Rs 1,200.50
    // - INR 450, INR 1,499.00
    // - ₹350, ₹ 1,200
    // - debited by Rs 400, paid 250, spent INR 500
    final amountPatterns = [
      RegExp(r'(?:Rs\.?|INR|\u20B9)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'(?:debited|spent|paid|withdrawn|credited|transferred|sent|deducted|payment of|txn of)\s+(?:by|for|of|with)?\s*(?:Rs\.?|INR|\u20B9)?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'([\d,]+(?:\.\d{1,2})?)\s*(?:Rs\.?|INR|\u20B9)?\s*(?:debited|spent|paid|withdrawn|credited|transferred|deducted)', caseSensitive: false),
    ];

    for (final pattern in amountPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final str = match.group(1)?.replaceAll(',', '').replaceAll('/-', '').trim();
        if (str != null) {
          final parsedAmt = double.tryParse(str);
          if (parsedAmt != null && parsedAmt > 0) {
            amount = parsedAmt;
            break;
          }
        }
      }
    }

    if (amount == null || amount <= 0) return null;

    // 3. Detect Credit (Income) vs Debit (Expense)
    final bool isIncome = _detectIsIncome(body, lowerBody);

    // 4. Extract Bank Source
    final String bankSource = _extractBankSource(sender, body);

    // 5. Extract Merchant / Payee
    final String merchant = _extractMerchant(
      body,
      lowerBody,
      bankSource: bankSource,
      isIncome: isIncome,
    );

    // 6. Categorize
    final String category = isIncome
        ? (lowerBody.contains('salary')
            ? 'Salary'
            : (lowerBody.contains('cashback')
                ? 'Cashback'
                : (lowerBody.contains('refund') ? 'Refund' : 'Income')))
        : _categorize(merchant, lowerBody);

    // 7. Payment Mode (UPI vs Card vs NetBanking vs Bank Transfer)
    String paymentMode = 'UPI';
    if (lowerBody.contains('card') || lowerBody.contains('credit card') || lowerBody.contains('debit card') || lowerBody.contains('pos')) {
      paymentMode = 'Card';
    } else if (lowerBody.contains('netbanking') || lowerBody.contains('imps') || lowerBody.contains('neft') || lowerBody.contains('rtgs') || isIncome) {
      paymentMode = isIncome ? 'Bank Transfer' : 'NetBanking';
    }

    // 8. Format Date / Time
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
      isIncome: isIncome,
      dateTime: dateTime.toIso8601String(),
    );
  }

  bool _detectIsIncome(String body, String lowerBody) {
    final hasCreditKeyword = lowerBody.contains('credited') ||
        lowerBody.contains('credit of') ||
        lowerBody.contains('credit by') ||
        lowerBody.contains('credit with') ||
        lowerBody.contains('has a credit') ||
        lowerBody.contains('received') ||
        lowerBody.contains('deposited') ||
        lowerBody.contains('refund') ||
        lowerBody.contains('cashback') ||
        lowerBody.contains('salary') ||
        lowerBody.contains('reversed');

    final hasDebitKeyword = lowerBody.contains('debited') ||
        lowerBody.contains('debit of') ||
        lowerBody.contains('debited by') ||
        lowerBody.contains('debited with') ||
        lowerBody.contains('spent') ||
        lowerBody.contains('paid') ||
        lowerBody.contains('sent to') ||
        lowerBody.contains('withdrawn') ||
        lowerBody.contains('deducted') ||
        lowerBody.contains('purchase') ||
        lowerBody.contains('auto-debit');

    if (hasCreditKeyword && !hasDebitKeyword) return true;
    if (hasDebitKeyword && !hasCreditKeyword) return false;

    // Both present: check which keyword appears first in message
    final cIdx = lowerBody.indexOf('credit');
    final dIdx = lowerBody.indexOf('debit');
    if (cIdx != -1 && dIdx != -1) {
      return cIdx < dIdx;
    }
    return hasCreditKeyword;
  }

  String _extractMerchant(
    String body,
    String lowerBody, {
    String? bankSource,
    bool isIncome = false,
  }) {
    if (isIncome) {
      // 1. Credit / Income: Search for sender/source
      final transferRegex = RegExp(
        r'(?:transfer from|trf from|received from|from|credit by|credited by|nach-)\s+([A-Za-z0-9\s*.\-_&@]+?)(?:\s+of|\s+on|\s+ref|\s+upi|\s+avl|\.|\,|$)',
        caseSensitive: false,
      );
      final tMatch = transferRegex.firstMatch(body);
      if (tMatch != null) {
        String name = tMatch.group(1)?.trim() ?? '';
        name = name.replaceAll(RegExp(r'^(the|a|an)\s+', caseSensitive: false), '');
        name = name.replaceAll(RegExp(r'^nach-\s*', caseSensitive: false), '');
        if (name.isNotEmpty && name.length <= 32 && !name.toLowerCase().contains('account')) {
          return _titleCase(name);
        }
      }

      if (lowerBody.contains('salary')) return 'Salary Credit';
      if (lowerBody.contains('refund')) return 'Refund';
      if (lowerBody.contains('cashback')) return 'Cashback';

      if (bankSource != null && bankSource.isNotEmpty && bankSource != 'Bank') {
        return '$bankSource Credit';
      }
      return 'Account Credit';
    }

    // 1. Direct famous brand check
    if (lowerBody.contains('swiggy')) return 'Swiggy';
    if (lowerBody.contains('zomato')) return 'Zomato';
    if (lowerBody.contains('uber')) return 'Uber';
    if (lowerBody.contains('ola')) return 'Ola Cabs';
    if (lowerBody.contains('rapido')) return 'Rapido';
    if (lowerBody.contains('blinkit')) return 'Blinkit';
    if (lowerBody.contains('zepto')) return 'Zepto';
    if (lowerBody.contains('instamart')) return 'Instamart';
    if (lowerBody.contains('bigbasket')) return 'BigBasket';
    if (lowerBody.contains('amazon')) return 'Amazon';
    if (lowerBody.contains('flipkart')) return 'Flipkart';
    if (lowerBody.contains('myntra')) return 'Myntra';
    if (lowerBody.contains('ajio')) return 'Ajio';
    if (lowerBody.contains('meesho')) return 'Meesho';
    if (lowerBody.contains('nykaa')) return 'Nykaa';
    if (lowerBody.contains('netflix')) return 'Netflix';
    if (lowerBody.contains('spotify')) return 'Spotify';
    if (lowerBody.contains('hotstar')) return 'Disney+ Hotstar';
    if (lowerBody.contains('prime video')) return 'Prime Video';
    if (lowerBody.contains('bookmyshow')) return 'BookMyShow';
    if (lowerBody.contains('pvr')) return 'PVR Cinemas';
    if (lowerBody.contains('inox')) return 'INOX';
    if (lowerBody.contains('irctc')) return 'IRCTC';
    if (lowerBody.contains('makemytrip')) return 'MakeMyTrip';
    if (lowerBody.contains('goibibo')) return 'Goibibo';
    if (lowerBody.contains('dmart')) return 'DMart';
    if (lowerBody.contains('reliance retail') || lowerBody.contains('smart bazaar')) return 'Reliance Smart';
    if (lowerBody.contains('zudio')) return 'Zudio';
    if (lowerBody.contains('airtel')) return 'Airtel';
    if (lowerBody.contains('jio')) return 'Jio Recharge';
    if (lowerBody.contains('google pay') || lowerBody.contains('gpay')) return 'Google Pay';
    if (lowerBody.contains('phonepe')) return 'PhonePe';
    if (lowerBody.contains('paytm')) return 'Paytm';
    // Precise Cred app matching (avoiding "credit" / "credited")
    if (RegExp(r'\bcred\b', caseSensitive: false).hasMatch(body) && !lowerBody.contains('credit')) return 'CRED';

    // 2. Regex heuristics for payee / merchant in text
    final merchantRegex = RegExp(
      r'(?:at|to|info\s*:?|towards|vpa|paid to|sent to|transfer to|trf to)\s+([A-Za-z0-9\s*.\-_&@]+?)(?:\s+on|\s+ref|\s+upi|\s+avl|\s+bal|\s+via|\s+thru|\s+using|\.|\,|$)',
      caseSensitive: false,
    );

    final match = merchantRegex.firstMatch(body);
    if (match != null) {
      String m = match.group(1)?.trim() ?? '';

      // Clean up common noise: UPI/DR/..., VPA..., A/c
      m = m.replaceAll(RegExp(r'^(the|a|an)\s+', caseSensitive: false), '');
      m = m.replaceAll(RegExp(r'^upi\s*/\s*(?:dr|cr)?\s*/?\s*', caseSensitive: false), '');
      m = m.replaceAll(RegExp(r'^vpa\s*:?\s*', caseSensitive: false), '');

      if (m.isNotEmpty &&
          m.length <= 30 &&
          !m.toLowerCase().contains('account') &&
          !m.toLowerCase().contains('card') &&
          !m.toLowerCase().contains('balance') &&
          !m.toLowerCase().contains('avl')) {
        return _titleCase(m);
      }
    }

    return 'Merchant / UPI';
  }

  String _extractBankSource(String sender, String body) {
    final s = sender.toUpperCase();
    final b = body.toUpperCase();

    if (s.contains('HDFC') || b.contains('HDFC')) return 'HDFC Bank';
    if (s.contains('SBI') || b.contains('SBI') || b.contains('STATE BANK')) return 'State Bank of India';
    if (s.contains('ICICI') || b.contains('ICICI')) return 'ICICI Bank';
    if (s.contains('AXIS') || b.contains('AXIS')) return 'Axis Bank';
    if (s.contains('KOTAK') || b.contains('KOTAK')) return 'Kotak Mahindra';
    if (s.contains('PNB') || b.contains('PUNJAB NATIONAL')) return 'Punjab National Bank';
    if (s.contains('BOB') || b.contains('BANK OF BARODA')) return 'Bank of Baroda';
    if (s.contains('CANARA') || b.contains('CANBNK') || b.contains('CANARA BANK')) return 'Canara Bank';
    if (s.contains('UNION') || b.contains('UNION BANK')) return 'Union Bank';
    if (s.contains('INDUS') || b.contains('INDUSIND')) return 'IndusInd Bank';
    if (s.contains('IDFC') || b.contains('IDFC FIRST')) return 'IDFC FIRST Bank';
    if (s.contains('YES') || b.contains('YES BANK')) return 'Yes Bank';
    if (s.contains('BOI') || b.contains('BANK OF INDIA')) return 'Bank of India';
    if (s.contains('FEDERAL') || b.contains('FEDBNK')) return 'Federal Bank';
    if (s.contains('RBL') || b.contains('RBLBNK')) return 'RBL Bank';
    if (s.contains('PAYTM') || b.contains('PAYTM BANK')) return 'Paytm Payments Bank';
    if (s.contains('AIRTEL') || b.contains('AIRTEL BANK')) return 'Airtel Payments Bank';
    if (s.contains('CITI') || b.contains('CITIBANK')) return 'Citibank';
    if (s.contains('SCB') || b.contains('STANDARD CHARTERED')) return 'Standard Chartered';
    if (s.contains('HSBC') || b.contains('HSBC BANK')) return 'HSBC';

    return 'Bank SMS';
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
        text.contains('coffee') ||
        text.contains('biryani') ||
        text.contains('haldiram') ||
        text.contains('eatclub')) {
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
        text.contains('iocl') ||
        text.contains('flight') ||
        text.contains('indigo') ||
        text.contains('makemytrip') ||
        text.contains('goibibo') ||
        text.contains('metro') ||
        text.contains('railway')) {
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
        text.contains('instamart') ||
        text.contains('bigbasket') ||
        text.contains('decathlon') ||
        text.contains('mall') ||
        text.contains('store')) {
      return 'Shopping';
    }

    if (text.contains('airtel') ||
        text.contains('jio') ||
        text.contains('vi ') ||
        text.contains('vodafone') ||
        text.contains('electricity') ||
        text.contains('bescom') ||
        text.contains('broadband') ||
        text.contains('wifi') ||
        text.contains('dth') ||
        text.contains('tata play') ||
        text.contains('recharge') ||
        text.contains('billdesk') ||
        text.contains('gas') ||
        text.contains('igl') ||
        text.contains('water')) {
      return 'Bills';
    }

    if (text.contains('netflix') ||
        text.contains('spotify') ||
        text.contains('hotstar') ||
        text.contains('prime video') ||
        text.contains('bookmyshow') ||
        text.contains('cinema') ||
        text.contains('pvr') ||
        text.contains('inox') ||
        text.contains('youtube')) {
      return 'Entertainment';
    }

    if (text.contains('apollo') ||
        text.contains('pharmacy') ||
        text.contains('1mg') ||
        text.contains('practo') ||
        text.contains('hospital') ||
        text.contains('clinic') ||
        text.contains('medplus') ||
        text.contains('pharmeasy') ||
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
