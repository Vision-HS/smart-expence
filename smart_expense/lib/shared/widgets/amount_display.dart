import 'package:flutter/material.dart';

class AmountDisplay extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final String currencySymbol;
  final bool showDecimals;

  const AmountDisplay({
    super.key,
    required this.amount,
    this.style,
    this.currencySymbol = '₹',
    this.showDecimals = false,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final formattedValue = showDecimals
        ? absAmount.toStringAsFixed(2)
        : (absAmount % 1 == 0
            ? absAmount.toInt().toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')
            : absAmount.toStringAsFixed(2));
    final sign = isNegative ? '-' : '+';
    
    return Text(
      '$sign$currencySymbol$formattedValue',
      style: style?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
