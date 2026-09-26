import 'dart:async';
import 'package:flutter/services.dart';
import '../../features/expenses/models/pending_sms_model.dart';
import '../../features/expenses/repositories/transaction_repository.dart';

class NotificationParserService {
  static final NotificationParserService instance =
      NotificationParserService._init();

  static const MethodChannel _methodChannel =
      MethodChannel('com.visionhs.smartexpense/notification_channel');
  static const EventChannel _eventChannel =
      EventChannel('com.visionhs.smartexpense/notification_stream');

  StreamController<PendingSmsModel>? _streamController;
  StreamSubscription? _nativeSubscription;

  NotificationParserService._init();

  /// Check if Notification Access permission is granted in Android
  Future<bool> checkPermission() async {
    try {
      final bool granted =
          await _methodChannel.invokeMethod('checkNotificationPermission') ??
              false;
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Opens Android Notification Access Settings screen
  Future<bool> requestPermission() async {
    try {
      final bool success =
          await _methodChannel.invokeMethod('requestNotificationPermission') ??
              false;
      return success;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _nativeSubscription?.cancel();
    _nativeSubscription = null;
    _streamController?.close();
    _streamController = null;
  }

  /// Real-time stream of parsed incoming payment notifications
  Stream<PendingSmsModel> get onIncomingNotification {
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
          final packageName = event['packageName']?.toString() ?? '';
          final title = event['title']?.toString() ?? '';
          final text = event['text']?.toString() ?? '';
          final timestamp = (event['timestamp'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch;

          final parsed = parseNotification(
            packageName: packageName,
            title: title,
            text: text,
            timestamp: timestamp,
          );

          if (parsed != null) {
            final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
            final isDup = await TransactionRepository.instance.isDuplicateRecent(
              amount: parsed.amount,
              isIncome: parsed.isIncome,
              timestamp: dt,
            );

            if (!isDup) {
              await TransactionRepository.instance.insertPendingSms(parsed);
              _streamController?.add(parsed);
            }
          }
        }
      },
      onError: (_) {},
    );
  }

  /// Sync notifications received while the app was closed or backgrounded
  Future<int> syncBufferedNotifications() async {
    try {
      final List<dynamic>? buffered =
          await _methodChannel.invokeMethod('getBufferedNotifications');
      if (buffered == null || buffered.isEmpty) return 0;

      int count = 0;
      for (final raw in buffered) {
        if (raw is Map) {
          final packageName = raw['packageName']?.toString() ?? '';
          final title = raw['title']?.toString() ?? '';
          final text = raw['text']?.toString() ?? '';
          final timestamp = (raw['timestamp'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch;

          final parsed = parseNotification(
            packageName: packageName,
            title: title,
            text: text,
            timestamp: timestamp,
          );

          if (parsed != null) {
            final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
            final isDup = await TransactionRepository.instance.isDuplicateRecent(
              amount: parsed.amount,
              isIncome: parsed.isIncome,
              timestamp: dt,
            );

            if (!isDup) {
              await TransactionRepository.instance.insertPendingSms(parsed);
              _streamController?.add(parsed);
              count++;
            }
          }
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// Parses an Android push notification into a [PendingSmsModel]
  PendingSmsModel? parseNotification({
    required String packageName,
    required String title,
    required String text,
    required int timestamp,
  }) {
    final lowerTitle = title.toLowerCase().trim();
    final lowerText = text.toLowerCase().trim();
    final combined = '$lowerTitle $lowerText';

    // 1. Promotional and loan offer rejection
    if (_isPromotionalOrNonTransaction(combined)) {
      return null;
    }

    // 2. Identify app / source
    final appSource = _identifySource(packageName, title);

    // 3. Extract amount
    final amount = _extractAmount(title, text);
    if (amount == null || amount <= 0) {
      return null;
    }

    // 4. Determine Debit vs Credit
    final isIncome = _isCreditTransaction(combined);

    // If neither clear credit nor debit verb is found, reject
    if (!isIncome && !_isDebitTransaction(combined)) {
      return null;
    }

    // 5. Extract merchant / payee / sender
    final merchant = _extractMerchant(
      title: title,
      text: text,
      isIncome: isIncome,
      appSource: appSource,
    );

    // 6. Category
    final category = _categorize(merchant, combined);

    // 7. Format time string
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    final timeString = '$hour:$minute $amPm';

    return PendingSmsModel(
      id: 'notif_${timestamp}_${amount.toInt()}',
      merchant: merchant,
      amount: amount,
      paymentMode: 'UPI',
      timeString: timeString,
      timeAgo: 'Just now',
      suggestedCategory: category,
      bankSource: appSource,
      isIncome: isIncome,
      dateTime: dt.toIso8601String(),
    );
  }

  bool _isPromotionalOrNonTransaction(String lowerCombined) {
    // Exclude loan offers, credit promos, cashback ads
    if (lowerCombined.contains('pre-approved') ||
        lowerCombined.contains('instant loan') ||
        lowerCombined.contains('eligible for loan') ||
        lowerCombined.contains('apply now') ||
        lowerCombined.contains('click here to') ||
        lowerCombined.contains('voucher worth') ||
        lowerCombined.contains('flat discount') ||
        lowerCombined.contains('cashback up to') ||
        lowerCombined.contains('special offer') ||
        lowerCombined.contains('use code') ||
        lowerCombined.contains('win exciting') ||
        lowerCombined.contains('scratch card waiting')) {
      return true;
    }
    return false;
  }

  String _identifySource(String packageName, String title) {
    final pkg = packageName.toLowerCase();
    final t = title.toLowerCase();

    if (pkg.contains('nbu.paisa') || t.contains('google pay') || t.contains('gpay')) {
      return 'Google Pay';
    }
    if (pkg.contains('phonepe') || t.contains('phonepe')) {
      return 'PhonePe';
    }
    if (pkg.contains('paytm') || t.contains('paytm')) {
      return 'Paytm';
    }
    if (pkg.contains('dreamplug') || t.contains('cred')) {
      return 'CRED';
    }
    if (pkg.contains('upiapp') || t.contains('bhim')) {
      return 'BHIM UPI';
    }
    if (pkg.contains('amazon') || t.contains('amazon pay')) {
      return 'Amazon Pay';
    }

    // Banks
    if (t.contains('hdfc') || pkg.contains('hdfc')) return 'HDFC Bank';
    if (t.contains('sbi') || pkg.contains('sbi')) return 'State Bank of India';
    if (t.contains('icici') || pkg.contains('icici')) return 'ICICI Bank';
    if (t.contains('axis') || pkg.contains('axis')) return 'Axis Bank';
    if (t.contains('kotak') || pkg.contains('kbank')) return 'Kotak Mahindra';
    if (t.contains('bob') || pkg.contains('bobmobile')) return 'Bank of Baroda';
    if (t.contains('pnb') || pkg.contains('pnb')) return 'PNB';

    if (title.isNotEmpty && title.length <= 25 && !t.contains('successful')) {
      return title.trim();
    }
    return 'UPI App';
  }

  double? _extractAmount(String title, String text) {
    final full = '$title $text';

    // Matches: ₹ 150, ₹150.00, Rs. 200, Rs 500, INR 1,200.50
    final patterns = [
      RegExp(r'(?:₹|rs\.?|inr)\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
      RegExp(r'([0-9,]+(?:\.[0-9]{1,2})?)\s*(?:₹|rs\.?|inr)', caseSensitive: false),
      RegExp(r'(?:paid|sent|received|debited|credited)\s*(?:of\s*)?(?:₹|rs\.?|inr)?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(full);
      if (match != null) {
        final rawStr = match.group(1)?.replaceAll(',', '').trim() ?? '';
        final val = double.tryParse(rawStr);
        if (val != null && val > 0) {
          return val;
        }
      }
    }

    return null;
  }

  bool _isCreditTransaction(String lowerCombined) {
    if (lowerCombined.contains('received') ||
        lowerCombined.contains('credited') ||
        lowerCombined.contains('money received') ||
        lowerCombined.contains('deposited') ||
        lowerCombined.contains('cashback credited') ||
        lowerCombined.contains('refund received')) {
      return true;
    }
    return false;
  }

  bool _isDebitTransaction(String lowerCombined) {
    if (lowerCombined.contains('paid') ||
        lowerCombined.contains('you paid') ||
        lowerCombined.contains('debited') ||
        lowerCombined.contains('sent') ||
        lowerCombined.contains('transferred') ||
        lowerCombined.contains('spent') ||
        lowerCombined.contains('bill payment') ||
        lowerCombined.contains('recharge of')) {
      return true;
    }
    return false;
  }

  String _extractMerchant({
    required String title,
    required String text,
    required bool isIncome,
    required String appSource,
  }) {
    final full = '$title $text';

    if (isIncome) {
      // e.g. "Received ₹500 from Ramesh Kumar" or "₹500 received from Sunita"
      final match = RegExp(r'from\s+([A-Za-z0-9\s*.\-_&@]+?)(?:\s+in|\s+using|\s+on|\.|$)', caseSensitive: false).firstMatch(full);
      if (match != null) {
        final m = match.group(1)?.trim() ?? '';
        if (m.isNotEmpty && m.length <= 32 && !m.toLowerCase().contains('account')) {
          return _formatName(m);
        }
      }
      return '$appSource Credit';
    }

    // Direct brand recognition
    final lower = full.toLowerCase();
    if (lower.contains('swiggy')) return 'Swiggy';
    if (lower.contains('zomato')) return 'Zomato';
    if (lower.contains('uber')) return 'Uber';
    if (lower.contains('ola')) return 'Ola Cabs';
    if (lower.contains('blinkit')) return 'Blinkit';
    if (lower.contains('zepto')) return 'Zepto';
    if (lower.contains('instamart')) return 'Instamart';
    if (lower.contains('bigbasket')) return 'BigBasket';
    if (lower.contains('amazon')) return 'Amazon';
    if (lower.contains('flipkart')) return 'Flipkart';
    if (lower.contains('myntra')) return 'Myntra';
    if (lower.contains('jio')) return 'Jio';
    if (lower.contains('airtel')) return 'Airtel';
    if (lower.contains('dmart')) return 'DMart';
    if (lower.contains('zudio')) return 'Zudio';
    if (lower.contains('irctc')) return 'IRCTC';

    // Pattern: "Paid to [Merchant]" or "Paid ₹... to [Merchant]" or "to [Merchant] using"
    final merchantPatterns = [
      RegExp(r'(?:paid\s*(?:₹|rs\.?|inr)?\s*[0-9,.]*\s*to|sent\s*(?:₹|rs\.?|inr)?\s*[0-9,.]*\s*to|paid to|transferred to)\s+([A-Za-z0-9\s*.\-_&@]+?)(?:\s+using|\s+from|\s+successfully|\s+via|\s+ref|\.|\,|$)', caseSensitive: false),
      RegExp(r'to\s+([A-Za-z0-9\s*.\-_&@]+?)(?:\s+using|\s+successfully|\.|$)', caseSensitive: false),
    ];

    for (final pattern in merchantPatterns) {
      final match = pattern.firstMatch(full);
      if (match != null) {
        var m = match.group(1)?.trim() ?? '';
        m = m.replaceAll(RegExp(r'^(the|a|an)\s+', caseSensitive: false), '');
        if (m.isNotEmpty &&
            m.length <= 32 &&
            !m.toLowerCase().contains('account') &&
            !m.toLowerCase().contains('bank') &&
            !m.toLowerCase().contains('wallet')) {
          return _formatName(m);
        }
      }
    }

    // Check title if title specifies payee (e.g. "Paid to Sharma Stores")
    if (title.toLowerCase().contains('paid to')) {
      final tMatch = RegExp(r'paid to\s+(.*)', caseSensitive: false).firstMatch(title);
      if (tMatch != null) {
        final m = tMatch.group(1)?.trim() ?? '';
        if (m.isNotEmpty && m.length <= 32) return _formatName(m);
      }
    }

    return '$appSource Payment';
  }

  String _formatName(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\w\s&.\-]'), '').trim();
    if (cleaned.isEmpty) return 'Merchant';
    return cleaned.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : '');
    }).join(' ');
  }

  String _categorize(String merchant, String lowerCombined) {
    final text = '${merchant.toLowerCase()} $lowerCombined';

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
        text.contains('chai')) {
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
        text.contains('railway') ||
        text.contains('metro')) {
      return 'Travel';
    }

    if (text.contains('blinkit') ||
        text.contains('zepto') ||
        text.contains('instamart') ||
        text.contains('bigbasket') ||
        text.contains('dmart') ||
        text.contains('grocery') ||
        text.contains('supermarket') ||
        text.contains('store') ||
        text.contains('kirana') ||
        text.contains('provision')) {
      return 'Groceries';
    }

    if (text.contains('amazon') ||
        text.contains('flipkart') ||
        text.contains('myntra') ||
        text.contains('ajio') ||
        text.contains('meesho') ||
        text.contains('nykaa') ||
        text.contains('zudio') ||
        text.contains('shopping') ||
        text.contains('mall')) {
      return 'Shopping';
    }

    if (text.contains('bill') ||
        text.contains('electricity') ||
        text.contains('bescom') ||
        text.contains('recharge') ||
        text.contains('airtel') ||
        text.contains('jio') ||
        text.contains('vi') ||
        text.contains('water') ||
        text.contains('gas') ||
        text.contains('broadband') ||
        text.contains('wifi') ||
        text.contains('postpaid')) {
      return 'Bills';
    }

    if (text.contains('hospital') ||
        text.contains('pharmacy') ||
        text.contains('medical') ||
        text.contains('clinic') ||
        text.contains('doctor') ||
        text.contains('medicine') ||
        text.contains('1mg') ||
        text.contains('apollo')) {
      return 'Health';
    }

    if (text.contains('netflix') ||
        text.contains('spotify') ||
        text.contains('hotstar') ||
        text.contains('prime video') ||
        text.contains('bookmyshow') ||
        text.contains('pvr') ||
        text.contains('inox') ||
        text.contains('cinema') ||
        text.contains('movie')) {
      return 'Entertainment';
    }

    return 'General';
  }
}
