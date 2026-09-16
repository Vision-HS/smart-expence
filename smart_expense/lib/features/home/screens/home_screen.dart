import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/sms_parser_service.dart';
import '../../expenses/models/pending_sms_model.dart';
import '../../expenses/models/transaction_model.dart';
import '../../expenses/repositories/transaction_repository.dart';
import '../../expenses/screens/add_expense_screen.dart';
import '../../transactions/screens/sms_detection_screen.dart';
import '../../expenses/screens/expenses_screen.dart';
import '../../transactions/screens/transaction_details_screen.dart';
import '../../settings/screens/profile_screen.dart';

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

  double _todaySpent = 0.0;
  int _todayOrders = 0;
  double _weekSpent = 0.0;
  double _monthSpent = 0.0;
  List<Map<String, dynamic>> _homeCategorySummary = [];
  String _currentMonth = TransactionModel.formatMonthYear(DateTime.now());
  String _displayName = 'Hiren';

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
      await TransactionRepository.instance.syncAndFixTransactionMonths();
      final months = await TransactionRepository.instance.getDistinctMonths();
      final monthToUse = months.isNotEmpty ? months.first : _currentMonth;
      final summary = await TransactionRepository.instance.getMonthSpendSummary(monthToUse);
      final pending = await TransactionRepository.instance.getPendingSms();
      final allTx = await TransactionRepository.instance.getAllTransactions();
      final quickMetrics = await TransactionRepository.instance.getQuickSpendingMetrics();
      final catSummary = await TransactionRepository.instance.getCategorySpendSummary(monthToUse);
      final savedName = await DatabaseHelper.instance.getSetting('display_name');

      if (mounted) {
        setState(() {
          _currentMonth = monthToUse;
          _totalSpent = summary['spent'] ?? 0.0;
          _totalReceived = summary['received'] ?? 0.0;
          _pendingCount = pending.length;
          _latestPending = pending.isNotEmpty ? pending.first : null;
          _recentTxns = allTx.take(3).toList();
          _todaySpent = (quickMetrics['todaySpent'] as num?)?.toDouble() ?? 0.0;
          _todayOrders = (quickMetrics['todayOrders'] as num?)?.toInt() ?? 0;
          _weekSpent = (quickMetrics['weekSpent'] as num?)?.toDouble() ?? 0.0;
          _monthSpent = (quickMetrics['monthSpent'] as num?)?.toDouble() ?? 0.0;
          _homeCategorySummary = catSummary;
          if (savedName != null && savedName.trim().isNotEmpty) {
            _displayName = savedName.trim();
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _handleRefresh() async {
    try {
      await SmsParserService.instance.syncInboxMessages(limit: 150);
    } catch (_) {}
    await _loadHomeData();
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
      final date = result['date'] as DateTime? ?? DateTime.now();
      final txn = TransactionModel(
        title: result['merchant'] ?? 'Custom Expense',
        amount: -amt.abs(),
        category: result['category'] ?? 'General',
        dateTime: date.toIso8601String(),
        account: result['payment'] ?? 'Default Account',
        paymentType: result['payment'] ?? 'UPI',
        isIncome: false,
        monthYear: TransactionModel.formatMonthYear(date),
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
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppTheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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

                // 3. Month Overview Card
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
      ),
    );
  }

  // Header: Greeting + Notification Bell + HS Avatar
  Widget _buildHeader(BuildContext context) {
    String initials = 'HS';
    if (_displayName.trim().isNotEmpty) {
      final parts = _displayName.trim().split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.first.isNotEmpty) {
        initials = parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning, $_displayName',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _currentMonth,
              style: const TextStyle(
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
            InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                _loadHomeData();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Inter',
                  ),
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
    final isCredit = p.isIncome;
    final headerBg = isCredit ? const Color(0xFFE6F7F0) : const Color(0xFFFFDAD6);
    final headerTextColor = isCredit ? const Color(0xFF006C49) : const Color(0xFFB61722);
    final headerTitle = isCredit ? 'LATEST CREDIT DETECTED' : 'LATEST DEBIT DETECTED';
    final headerIcon = isCredit ? Icons.arrow_downward_rounded : Icons.flash_on_rounded;
    final amountColor = isCredit ? const Color(0xFF006C49) : const Color(0xFFBA1A1A);
    final confirmButtonColor = isCredit ? const Color(0xFF006C49) : const Color(0xFF4648D4);
    final confirmText = isCredit ? 'Confirm Income' : 'Confirm Expense';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCredit ? const Color(0x59006C49) : const Color(0x59DA3437),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isCredit ? const Color(0x10006C49) : const Color(0x10DA3437),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(headerIcon, size: 16, color: headerTextColor),
                    const SizedBox(width: 5),
                    Text(
                      headerTitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: headerTextColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  p.timeAgo,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: headerTextColor,
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
                              color: isCredit ? const Color(0xFFE6F7F0) : const Color(0xFFF2F3FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isCredit ? Icons.account_balance_wallet_rounded : p.categoryIcon,
                              color: isCredit ? const Color(0xFF006C49) : AppTheme.primary,
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
                      '${isCredit ? '+' : '-'}₹$amtFormatted',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: amountColor,
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
                          backgroundColor: confirmButtonColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          await TransactionRepository.instance.confirmSmsTransaction(
                            p,
                            chosenCategory: p.suggestedCategory,
                          );
                          _loadHomeData();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✓ ₹$amtFormatted ${isCredit ? 'income' : 'expense'} confirmed!'),
                                backgroundColor: const Color(0xFF006C49),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                        label: Text(
                          confirmText,
                          style: const TextStyle(
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
    final double netBalance = _totalReceived - _totalSpent;
    final String balanceStr = netBalance < 0
        ? '-₹${_formatCurrency(netBalance.abs().toInt())}'
        : '₹${_formatCurrency(netBalance.toInt())}';

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
            children: [
              Text(
                '${_currentMonth.toUpperCase()} OVERVIEW',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const Icon(
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
            balanceStr,
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
          value: '₹${_formatCurrency(_todaySpent.toInt())}',
          subtext: '$_todayOrders txns',
          subtextColor: AppTheme.textMuted,
        ),
        const SizedBox(width: 8),
        _buildMetricItem(
          title: 'This Week',
          value: '₹${_formatCurrency(_weekSpent.toInt())}',
          subtext: 'Past 7 days',
          subtextColor: const Color(0xFF006C49),
        ),
        const SizedBox(width: 8),
        _buildMetricItem(
          title: 'This Month',
          value: '₹${_formatCurrency((_monthSpent > 0 ? _monthSpent : _totalSpent).toInt())}',
          subtext: _currentMonth,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Spending by Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                _totalSpent > 0 ? 'Total: ₹${_formatCurrency(_totalSpent.toInt())}' : 'No Spends',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_homeCategorySummary.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No category expenses recorded for this month.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            )
          else
            ..._homeCategorySummary.take(4).map((item) {
              final catName = item['category'] as String? ?? 'Other';
              final amt = (item['total'] as num?)?.toDouble() ?? 0.0;
              final progress = _totalSpent > 0 ? (amt / _totalSpent).clamp(0.0, 1.0) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: _buildCategoryProgressItem(
                  icon: TransactionModel.getIconForCategory(catName),
                  title: catName,
                  amount: '₹${_formatCurrency(amt.toInt())}',
                  progress: progress,
                ),
              );
            }),
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
                onTap: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailsScreen(
                        transaction: tx,
                        id: tx.id,
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
                  if (res == true) {
                    _loadHomeData();
                  }
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

