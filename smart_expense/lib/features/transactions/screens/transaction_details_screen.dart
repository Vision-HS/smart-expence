import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final String title;
  final bool isVerified;
  final String category;
  final double amount;
  final String status;
  final String paymentMethod;
  final String dateTime;
  final String upiId;
  final String bankAccount;
  final String referenceId;
  final String expenseSource;
  final String bankAlertBody;

  const TransactionDetailsScreen({
    super.key,
    this.title = 'Rahul',
    this.isVerified = true,
    this.category = 'Food & Dining',
    this.amount = -500.00,
    this.status = 'Completed via UPI',
    this.paymentMethod = 'UPI Transfer',
    this.dateTime = '03 Sep 2026, 09:15 AM',
    this.upiId = 'rahul123@upi',
    this.bankAccount = 'HDFC Bank •• 4821',
    this.referenceId = '123456789012',
    this.expenseSource = 'Verified SMS',
    this.bankAlertBody =
        'Debited INR 500.00 via UPI from A/C XX4821 to Rahul on 03-Sep-26 Ref 123456789012. Bal info in NetBanking.',
  });

  @override
  Widget build(BuildContext context) {
    final formattedAmount = (amount < 0 ? '-₹' : '+₹') +
        amount.abs().toStringAsFixed(2).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
            );

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. App Bar Row
              _buildAppBar(context),
              const SizedBox(height: 12),

              // 2. Sync Status + Share Button
              _buildSyncRow(context),
              const SizedBox(height: 16),

              // 3. Main Transaction Hero Card
              _buildHeroCard(formattedAmount),
              const SizedBox(height: 14),

              // 4. Action Cards (Add receipt, Split bill)
              _buildActionCards(context),
              const SizedBox(height: 14),

              // 5. Detailed Attributes Card
              _buildAttributesCard(context),
              const SizedBox(height: 14),

              // 6. Original Bank Alert Card
              _buildBankAlertCard(),
              const SizedBox(height: 24),

              // 7. Bottom Actions: Edit & Delete
              _buildBottomButtons(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // App Bar: Back arrow, "Expense Details", User silhouette avatar
  Widget _buildAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppTheme.textPrimary,
                size: 24,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 14),
            const Text(
              'Expense Details',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.person_rounded,
            size: 22,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // Sync status row with share button
  Widget _buildSyncRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF006C49),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Transaction synced instantly',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction details ready to share'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.share_outlined,
              size: 18,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // Hero Transaction Summary Card
  Widget _buildHeroCard(String formattedAmount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        children: [
          // Circular Category Icon (Food & Dining cutlery)
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_outlined,
              size: 26,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Title + Verified checkmark
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: Color(0xFF006C49),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // Category Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Big Amount Display
          Text(
            formattedAmount,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: amount < 0
                  ? const Color(0xFFBA1A1A)
                  : const Color(0xFF006C49),
              fontFamily: 'Inter',
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Completed via UPI Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 14,
                  color: Color(0xFF006C49),
                ),
                const SizedBox(width: 6),
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF006C49),
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Two action cards: Add receipt & Split bill
  Widget _buildActionCards(BuildContext context) {
    return Row(
      children: [
        // Add Receipt
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    size: 20,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Add receipt',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Attach photo',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Split Bill
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.group_add_outlined,
                    size: 20,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Split bill',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'With friends',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Detailed Attributes Card
  Widget _buildAttributesCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        children: [
          // 1. Payment Method
          _buildAttributeRow(
            label: 'Payment Method',
            rightWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  paymentMethod,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          _buildDivider(),

          // 2. Date & Time
          _buildAttributeRow(
            label: 'Date & Time',
            rightWidget: Text(
              dateTime,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          _buildDivider(),

          // 3. UPI ID
          _buildAttributeRow(
            label: 'UPI ID',
            rightWidget: Text(
              upiId,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          _buildDivider(),

          // 4. Bank Account
          _buildAttributeRow(
            label: 'Bank Account',
            rightWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'H',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  bankAccount,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          _buildDivider(),

          // 5. Reference ID (UTR) with Copy Action
          _buildAttributeRow(
            label: 'Reference ID (UTR)',
            rightWidget: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: referenceId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied Reference ID $referenceId'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    referenceId,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.copy_rounded,
                    size: 15,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ),
          _buildDivider(),

          // 6. Expense Source
          _buildAttributeRow(
            label: 'Expense Source',
            rightWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 13,
                    color: Color(0xFF006C49),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    expenseSource,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF006C49),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeRow({
    required String label,
    required Widget rightWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          rightWidget,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF2F3FF),
      indent: 16,
      endIndent: 16,
    );
  }

  // Original Bank Alert Box
  Widget _buildBankAlertCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 18,
                    color: AppTheme.textPrimary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ORIGINAL BANK ALERT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              Row(
                children: const [
                  Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              bankAlertBody,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                height: 1.45,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom action buttons: Edit & Delete
  Widget _buildBottomButtons(BuildContext context) {
    return Row(
      children: [
        // Edit Button
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit transaction pressed'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: AppTheme.surface,
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.border, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.edit_outlined, size: 18, color: AppTheme.textPrimary),
                  SizedBox(width: 6),
                  Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Delete Button
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction deleted'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFDAD6),
                foregroundColor: const Color(0xFFBA1A1A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Color(0xFFBA1A1A),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

