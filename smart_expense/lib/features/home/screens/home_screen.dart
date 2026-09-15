import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/sms_parser_service.dart';
import '../../expenses/models/pending_sms_model.dart';
import '../../expenses/models/transaction_model.dart';
import '../../expenses/repositories/transaction_repository.dart';
import '../../expenses/screens/add_expense_screen.dart';
import '../../transactions/screens/sms_detection_screen.dart';
import '../../expenses/screens/expenses_screen.dart';
import '../../transactions/screens/transaction_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onViewAllPressed;

  const HomeScreen({super.key, this.onViewAllPressed});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _totalSpent = 0.0;
  double _totalReceived = 0.0;
  int _pendingCount = 0;
  PendingSmsModel? _latestPending;
  List<TransactionModel> _recentTxns = [];
  StreamSubscription<PendingSmsModel>? _smsSubscription;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    _smsSubscription = SmsParserService.instance.onIncomingSms.listen((_) {
      if (mounted) {
        _loadHomeData();
      }
    });
  }

  @override
  void dispose() {
    _smsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    try {
      final summary = await TransactionRepository.instance.getMonthSpendSummary('September 2024');
      final pending = await TransactionRepository.instance.getPendingSms();
      final allTx = await TransactionRepository.instance.getAllTransactions();

      if (mounted) {
        setState(() {
          _totalSpent = summary['spent'] ?? 0.0;
          _totalReceived = summary['received'] ?? 0.0;
          _pendingCount = pending.length;
          _latestPending = pending.isNotEmpty ? pending.first : null;
          _recentTxns = allTx.take(3).toList();
        });
      }
    } catch (_) {}
  }

  String _formatCurrency(int val) {
    return val.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _openAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
    if (result != null && result is Map<String, dynamic>) {
      final amt = (result['amount'] as num).toDouble();
      final txn = TransactionModel(
        title: result['merchant'] ?? 'Custom Expense',
        amount: -amt.abs(),
        category: result['category'] ?? 'General',
        dateTime: DateTime.now().toIso8601String(),
        account: result['payment'] ?? 'Default Account',
        paymentType: result['payment'] ?? 'UPI',
        isIncome: false,
        monthYear: 'September 2024',
        notes: result['notes'],
      );
      await TransactionRepository.instance.insertTransaction(txn);
    }
    _loadHomeData();
  }

  void _openSmsDetection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SmsDetectionScreen()),
    );
    _loadHomeData();
  }

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
              onTap: _openSmsDetection,
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
                    if (_pendingCount > 0)
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
    if (_pendingCount == 0 || _latestPending == null) {
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
                Icons.check_circle_outline_rounded,
                size: 18,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'All transactions synchronized',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            InkWell(
              onTap: _openSmsDetection,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: const [
                    Text(
                      'Open',
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

    final p = _latestPending!;
    final amtFormatted = p.amount == p.amount.roundToDouble()
        ? p.amount.toInt().toString()
        : p.amount.toStringAsFixed(2);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x59DA3437), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10DA3437),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Strip: LATEST TRANSACTION DETECTED
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFDAD6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFFB61722)),
                    SizedBox(width: 5),
                    Text(
                      'LATEST DEBIT DETECTED',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFFB61722),
                      ),
                    ),
                  ],
                ),
                Text(
                  p.timeAgo,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB61722),
                  ),
                ),
              ],
            ),
          ),
          // Content Details
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F3FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              p.categoryIcon,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.merchant,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${p.bankSource} • ${p.paymentMode}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFF767586),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '-₹$amtFormatted',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFBA1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4648D4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          await TransactionRepository.instance.confirmSmsTransaction(
                            p,
                            chosenCategory: p.suggestedCategory,
                            monthYear: 'September 2024',
                          );
                          _loadHomeData();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✓ ₹$amtFormatted confirmed into expenses!'),
                                backgroundColor: const Color(0xFF006C49),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                        label: const Text(
                          'Confirm Expense',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        side: const BorderSide(color: Color(0xFFC7C4D7)),
                      ),
                      onPressed: _openSmsDetection,
                      child: Text(
                        _pendingCount > 1 ? 'View All ($_pendingCount)' : 'Details',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
          Text(
            '₹${_formatCurrency((_totalReceived - _totalSpent).toInt())}',
            style: const TextStyle(
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
                      Text(
                        '₹${_formatCurrency(_totalReceived.toInt())}',
                        style: const TextStyle(
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
                      Text(
                        '₹${_formatCurrency(_totalSpent.toInt())}',
                        style: const TextStyle(
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
              onTap: () async {
                if (widget.onViewAllPressed != null) {
                  widget.onViewAllPressed!();
                } else {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExpensesScreen()),
                  );
                  _loadHomeData();
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
        if (_recentTxns.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border, width: 1),
            ),
            alignment: Alignment.center,
            child: const Text(
              'No transactions recorded yet.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentTxns.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tx = _recentTxns[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailsScreen(
                        title: tx.title,
                        isVerified: true,
                        category: tx.category,
                        amount: tx.amount,
                        status: tx.isIncome
                            ? 'Completed via Bank Transfer'
                            : 'Completed via ${tx.paymentType}',
                        paymentMethod: tx.paymentType,
                        dateTime: tx.dateGroup,
                        bankAccount: tx.account,
                        expenseSource: tx.rawSms != null ? 'Verified SMS' : 'Manual Entry',
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
                          color: tx.iconBgColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          tx.icon,
                          size: 20,
                          color: tx.iconColor,
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
                            '${tx.isIncome ? '+' : '-'}₹${_formatCurrency(tx.amount.abs().toInt())}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: tx.isIncome
                                  ? const Color(0xFF006C49)
                                  : const Color(0xFFBA1A1A),
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
        onPressed: _openAddExpense,
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

