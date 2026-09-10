import 'package:flutter/material.dart';

class PendingSmsModel {
  final String id;
  String merchant;
  double amount;
  String paymentMode;
  String timeString;
  String timeAgo;
  String suggestedCategory;
  String bankSource;
  bool isSecondCard;

  PendingSmsModel({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.paymentMode,
    required this.timeString,
    required this.timeAgo,
    required this.suggestedCategory,
    required this.bankSource,
    this.isSecondCard = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'paymentMode': paymentMode,
      'timeString': timeString,
      'timeAgo': timeAgo,
      'suggestedCategory': suggestedCategory,
      'bankSource': bankSource,
      'isSecondCard': isSecondCard ? 1 : 0,
    };
  }

  factory PendingSmsModel.fromMap(Map<String, dynamic> map) {
    return PendingSmsModel(
      id: map['id'] as String,
      merchant: map['merchant'] as String? ?? 'Merchant',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: map['paymentMode'] as String? ?? 'UPI',
      timeString: map['timeString'] as String? ?? 'Just now',
      timeAgo: map['timeAgo'] as String? ?? 'Just now',
      suggestedCategory: map['suggestedCategory'] as String? ?? 'General',
      bankSource: map['bankSource'] as String? ?? 'SMS',
      isSecondCard: (map['isSecondCard'] as int? ?? 0) == 1,
    );
  }

  PendingSmsModel copyWith({
    String? id,
    String? merchant,
    double? amount,
    String? paymentMode,
    String? timeString,
    String? timeAgo,
    String? suggestedCategory,
    String? bankSource,
    bool? isSecondCard,
  }) {
    return PendingSmsModel(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      timeString: timeString ?? this.timeString,
      timeAgo: timeAgo ?? this.timeAgo,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      bankSource: bankSource ?? this.bankSource,
      isSecondCard: isSecondCard ?? this.isSecondCard,
    );
  }

  // UI Presentation Helpers
  IconData get categoryIcon {
    switch (suggestedCategory.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'travel':
        return Icons.directions_car_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'bills':
        return Icons.receipt_long_outlined;
      case 'health':
        return Icons.medical_services_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  IconData get bankIcon {
    if (paymentMode.toLowerCase() == 'card') {
      return Icons.credit_card_outlined;
    }
    return Icons.account_balance_outlined;
  }

  IconData get merchantIcon {
    switch (suggestedCategory.toLowerCase()) {
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'food':
        return Icons.person_outline_rounded;
      case 'travel':
        return Icons.directions_car_outlined;
      default:
        return Icons.storefront_outlined;
    }
  }

  Color get merchantIconBg {
    if (suggestedCategory.toLowerCase() == 'shopping') {
      return const Color(0xFF6CF8BB);
    }
    return const Color(0xFFEAEDFF);
  }

  Color get merchantIconColor {
    if (suggestedCategory.toLowerCase() == 'shopping') {
      return const Color(0xFF006C49);
    }
    return const Color(0xFF4648D4);
  }
}
