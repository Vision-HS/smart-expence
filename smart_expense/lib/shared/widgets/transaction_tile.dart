import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'amount_display.dart';

enum TransactionType { income, expense, pending }

class TransactionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final TransactionType type;
  final IconData icon;
  final String? accountSource;

  const TransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
    required this.icon,
    this.accountSource,
  });

  @override
  Widget build(BuildContext context) {
    Color iconBackgroundColor;
    Color iconColor;
    Color amountColor;

    switch (type) {
      case TransactionType.income:
        iconBackgroundColor = AppTheme.secondaryContainer;
        iconColor = AppTheme.secondary;
        amountColor = AppTheme.secondary;
        break;
      case TransactionType.expense:
        iconBackgroundColor = AppTheme.errorContainer;
        iconColor = AppTheme.error;
        amountColor = AppTheme.textPrimary;
        break;
      case TransactionType.pending:
        iconBackgroundColor = AppTheme.warningContainer;
        iconColor = AppTheme.warning;
        amountColor = AppTheme.textPrimary;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AmountDisplay(
                  amount: amount,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
                if (accountSource != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    accountSource!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
