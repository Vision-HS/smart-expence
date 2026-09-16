import 'package:flutter/material.dart';

class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final String dateTime; // ISO 8601 string or display string
  final String account;
  final String paymentType;
  final bool isIncome;
  final String monthYear; // e.g. "September 2024", "October 2024"
  final bool isSynced;
  final String? rawSms;
  final String? notes;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.dateTime,
    required this.account,
    required this.paymentType,
    required this.isIncome,
    required this.monthYear,
    this.isSynced = true,
    this.rawSms,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'dateTime': dateTime,
      'account': account,
      'paymentType': paymentType,
      'isIncome': isIncome ? 1 : 0,
      'monthYear': monthYear,
      'isSynced': isSynced ? 1 : 0,
      'rawSms': rawSms,
      'notes': notes,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    final dtStr = map['dateTime'] as String? ?? DateTime.now().toIso8601String();
    final dt = DateTime.tryParse(dtStr) ?? DateTime.now();
    final defaultMonth = formatMonthYear(dt);
    final rawMonth = map['monthYear'] as String?;
    final resolvedMonth = (rawMonth != null && rawMonth.isNotEmpty && rawMonth != 'September 2024')
        ? rawMonth
        : defaultMonth;

    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? 'Transaction',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? 'General',
      dateTime: dtStr,
      account: map['account'] as String? ?? 'Account',
      paymentType: map['paymentType'] as String? ?? 'UPI',
      isIncome: (map['isIncome'] as int? ?? 0) == 1,
      monthYear: resolvedMonth,
      isSynced: (map['isSynced'] as int? ?? 1) == 1,
      rawSms: map['rawSms'] as String?,
      notes: map['notes'] as String?,
    );
  }

  static const List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static String formatMonthYear(DateTime dt) {
    return '${monthNames[dt.month - 1]} ${dt.year}';
  }

  TransactionModel copyWith({
    int? id,
    String? title,
    double? amount,
    String? category,
    String? dateTime,
    String? account,
    String? paymentType,
    bool? isIncome,
    String? monthYear,
    bool? isSynced,
    String? rawSms,
    String? notes,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      account: account ?? this.account,
      paymentType: paymentType ?? this.paymentType,
      isIncome: isIncome ?? this.isIncome,
      monthYear: monthYear ?? this.monthYear,
      isSynced: isSynced ?? this.isSynced,
      rawSms: rawSms ?? this.rawSms,
      notes: notes ?? this.notes,
    );
  }

  static IconData getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & dining':
        return Icons.restaurant_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'travel':
        return Icons.directions_car_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'bills':
      case 'bills & utilities':
        return Icons.receipt_long_outlined;
      case 'groceries':
        return Icons.shopping_cart_outlined;
      case 'salary':
      case 'income':
        return Icons.payments_outlined;
      case 'health':
        return Icons.medical_services_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  // UI Presentation Helpers
  IconData get icon => getIconForCategory(category);

  Color get iconBgColor {
    if (isIncome) return const Color(0xFFDCFCE7);
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & dining':
        return const Color(0xFFFEF2F2);
      case 'shopping':
        return const Color(0xFFFEF2F2);
      case 'travel':
        return const Color(0xFFEAEDFF);
      case 'entertainment':
        return const Color(0xFFFEF3C7);
      case 'bills':
      case 'bills & utilities':
        return const Color(0xFFF1F5F9);
      default:
        return const Color(0xFFEAEDFF);
    }
  }

  Color get iconColor {
    if (isIncome) return const Color(0xFF006C49);
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & dining':
      case 'shopping':
        return const Color(0xFFBA1A1A);
      case 'travel':
        return const Color(0xFF4648D4);
      case 'entertainment':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF4648D4);
    }
  }

  String get dateGroup {
    try {
      final dt = DateTime.tryParse(dateTime);
      if (dt != null) {
        final now = DateTime.now();
        if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
          return 'TODAY';
        }
        final yesterday = now.subtract(const Duration(days: 1));
        if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
          return 'YESTERDAY';
        }
      }
    } catch (_) {}
    return 'RECENT';
  }

  String get subtitle {
    return '$category • $paymentType • ${account.isNotEmpty ? account : "Account"}';
  }
}
