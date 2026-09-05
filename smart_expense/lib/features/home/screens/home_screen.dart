import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../expenses/screens/add_expense_screen.dart';
import '../../transactions/screens/sms_detection_screen.dart';
import '../../expenses/screens/expenses_screen.dart';
import '../../transactions/screens/transaction_details_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onViewAllPressed;

  const HomeScreen({super.key, this.onViewAllPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header / Profile Bar
              _buildHeader(context),
              const SizedBox(height: 16),

              // 2. SMS Detection Banner
              _buildSmsDetectionBanner(context),
              const SizedBox(height: 16),

              // 3. September Overview Card
              _buildOverviewCard(context),
              const SizedBox(height: 12),

              // 4. Quick Metric Cards (Today, This Week, This Month)
              _buildQuickMetricsRow(context),
              const SizedBox(height: 16),

              // 5. Spending by Category Card
              _buildSpendingByCategoryCard(context),
              const SizedBox(height: 20),

              // 6. Recent Transactions Section
              _buildRecentTransactionsSection(context),
              const SizedBox(height: 20),

              // 7. Add Expense Manually Button
              _buildAddExpenseButton(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Header: Greeting + Notification Bell + HS Avatar
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Good morning, Hiren',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: 2),
            Text(
              'September 2026',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Notification Bell with unread dot
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SmsDetectionScreen()),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      size: 20,
                      color: AppTheme.textPrimary,
                    ),
                    Positioned(
                      top: 9,
                      right: 10,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBA1A1A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // User Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                'HS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // SMS Transaction Detection Alert Banner
  Widget _buildSmsDetectionBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.surfaceContainerHigh,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 18,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '2 new SMS transactions detected',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SmsDetectionScreen()),
              );
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: const [
                  Text(
                    'Review',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // September Overview Card with Total Available Balance & Income/Expense sub-boxes
  Widget _buildOverviewCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'SEPTEMBER OVERVIEW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 19,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Total Available Balance',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '₹31,550',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
              fontFamily: 'Inter',
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          // Sub metric boxes: Income & Expenses
          Row(
            children: [
              // Income
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6CF8BB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 13,
                              color: Color(0xFF006C49),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Income',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '₹50,000',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF006C49),
                          fontFamily: 'Inter',
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Expenses
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFDAD6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.remove,
                              size: 13,
                              color: Color(0xFFBA1A1A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Expenses',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '₹18,450',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFBA1A1A),
                          fontFamily: 'Inter',
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3 Quick Metric Cards: Today, This Week, This Month
  Widget _buildQuickMetricsRow(BuildContext context) {
    return Row(
      children: [
        _buildMetricItem(
          title: 'Today',
          value: '₹850',
          subtext: '3 orders',
          subtextColor: AppTheme.textMuted,
        ),
        const SizedBox(width: 8),
        _buildMetricItem(
          title: 'This Week',
          value: '₹4,250',
          subtext: '-12% vs last',
          subtextColor: const Color(0xFF006C49),
        ),
        const SizedBox(width: 8),
        _buildMetricItem(
          title: 'This Month',
          value: '₹18,450',
          subtext: '62% of cap',
          subtextColor: AppTheme.textMuted,
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required String title,
    required String value,
    required String subtext,
    required Color subtextColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtext,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: subtextColor,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Spending by Category Card with progress indicators
  Widget _buildSpendingByCategoryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Spending by Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                'Budget: ₹30,000',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCategoryProgressItem(
            icon: Icons.restaurant_outlined,
            title: 'Food & Dining',
            amount: '₹4,500',
            progress: 0.55,
          ),
          const SizedBox(height: 14),
          _buildCategoryProgressItem(
            icon: Icons.receipt_long_outlined,
            title: 'Bills & Utilities',
            amount: '₹5,000',
            progress: 0.65,
          ),
          const SizedBox(height: 14),
          _buildCategoryProgressItem(
            icon: Icons.shopping_bag_outlined,
            title: 'Shopping',
            amount: '₹3,200',
            progress: 0.42,
          ),
          const SizedBox(height: 14),
          _buildCategoryProgressItem(
            icon: Icons.directions_car_outlined,
            title: 'Travel',
            amount: '₹2,100',
            progress: 0.28,
            progressColor: const Color(0xFF9FA2F6),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryProgressItem({
    required IconData icon,
    required String title,
    required String amount,
    required double progress,
    Color? progressColor,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            const Spacer(),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppTheme.surfaceContainerLow,
            valueColor: AlwaysStoppedAnimation<Color>(
              progressColor ?? AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  // Recent Transactions Section
  Widget _buildRecentTransactionsSection(BuildContext context) {
    final transactions = [
      _TransactionItem(
        title: 'Amazon',
        subtitle: 'Shopping • Today, 10:42 AM',
        amount: '-₹1,299',
        account: 'ICICI Bank',
        icon: Icons.shopping_cart_outlined,
        isExpense: true,
      ),
      _TransactionItem(
        title: 'Rahul',
        subtitle: 'UPI Transfer • Today, 09:15 AM',
        amount: '-₹500',
        account: 'GPay',
        icon: Icons.north_east_rounded,
        isExpense: true,
      ),
      _TransactionItem(
        title: 'Salary',
        subtitle: 'Bank Transfer • Yesterday',
        amount: '+₹50,000',
        account: 'HDFC Corp',
        icon: Icons.payments_outlined,
        isExpense: false,
      ),
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            GestureDetector(
              onTap: () {
                if (onViewAllPressed != null) {
                  onViewAllPressed!();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExpensesScreen()),
                  );
                }
              },
              child: Row(
                children: const [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionDetailsScreen(
                      title: tx.title,
                      isVerified: true,
                      category: tx.title == 'Rahul'
                          ? 'Food & Dining'
                          : (tx.title == 'Amazon' ? 'Shopping' : 'Income'),
                      amount: tx.title == 'Salary' ? 50000.0 : (tx.title == 'Amazon' ? -1299.0 : -500.0),
                      status: tx.title == 'Salary' ? 'Credited to Bank' : 'Completed via UPI',
                      paymentMethod: tx.title == 'Salary' ? 'Bank Transfer' : 'UPI Transfer',
                      dateTime: '03 Sep 2026, 09:15 AM',
                      upiId: '${tx.title.toLowerCase()}@upi',
                      bankAccount: tx.account,
                      referenceId: '123456789012',
                      expenseSource: 'Verified SMS',
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tx.isExpense
                          ? const Color(0xFFFFE8E8)
                          : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      tx.icon,
                      size: 20,
                      color: tx.isExpense
                          ? const Color(0xFFBA1A1A)
                          : const Color(0xFF006C49),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tx.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        tx.amount,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: tx.isExpense
                              ? const Color(0xFFBA1A1A)
                              : const Color(0xFF006C49),
                          fontFamily: 'Inter',
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tx.account,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        ),
      ],
    );
  }

  // + Add Expense Manually Button
  Widget _buildAddExpenseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, size: 20, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Add Expense Manually',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionItem {
  final String title;
  final String subtitle;
  final String amount;
  final String account;
  final IconData icon;
  final bool isExpense;

  const _TransactionItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.account,
    required this.icon,
    required this.isExpense,
  });
}

