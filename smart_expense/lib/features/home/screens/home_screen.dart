import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/sms_parser_service.dart';
import '../../../core/services/notification_parser_service.dart';
import '../../../core/widgets/neumorphic/neu_card.dart';
import '../../../core/widgets/neumorphic/neu_inset.dart';
import '../../../core/widgets/neumorphic/neu_button.dart';
import '../../../core/widgets/neumorphic/neu_icon_button.dart';
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
  StreamSubscription<PendingSmsModel>? _notifSubscription;

  double _todaySpent = 0.0;
  int _todayOrders = 0;
  double _weekSpent = 0.0;
  double _monthSpent = 0.0;
  List<Map<String, dynamic>> _homeCategorySummary = [];
  String _currentMonth = TransactionModel.formatMonthYear(DateTime.now());
  String _displayName = 'User';

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    _setupRealtimeListener();
    NotificationParserService.instance.syncBufferedNotifications();
    _checkNotificationAccess();
  }

  Future<void> _checkNotificationAccess() async {
    // Wait a moment for the UI to settle before showing prompts
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final hasPermission = await NotificationParserService.instance.checkPermission();

    if (hasPermission) {
      // Permission is granted — force rebind to ensure service is actively connected
      await NotificationParserService.instance.requestRebind();
      // Sync any buffered notifications from background
      await NotificationParserService.instance.syncBufferedNotifications();
      return;
    }

    if (!mounted) return;

    // Show a user-friendly bottom sheet prompting to enable notification access
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xFFF59E0B),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Notification Access Required',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Smart Expense needs Notification Access to automatically detect your UPI payments from Google Pay, PhonePe, Paytm, etc.\n\nPlease enable "Smart Expense Notification Reader" on the next screen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await NotificationParserService.instance.requestPermission();
                  // After user returns from Settings, re-check and rebind
                  await Future.delayed(const Duration(seconds: 3));
                  final nowGranted = await NotificationParserService.instance.checkPermission();
                  if (nowGranted) {
                    await NotificationParserService.instance.requestRebind();
                    await NotificationParserService.instance.syncBufferedNotifications();
                    if (mounted) _loadHomeData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4648D4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Enable Notification Access',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Skip for Now',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _setupRealtimeListener() {
    _smsSubscription = SmsParserService.instance.onIncomingSms.listen((_) {
      if (mounted) {
        _loadHomeData();
      }
    });
    _notifSubscription = NotificationParserService.instance.onIncomingNotification.listen((_) {
      if (mounted) {
        _loadHomeData();
      }
    });
  }

  @override
  void dispose() {
    _smsSubscription?.cancel();
    _notifSubscription?.cancel();
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
      await NotificationParserService.instance.syncBufferedNotifications();
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

  // Header: Greeting + Theme Toggle + Notification Bell + HS Avatar
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

    final isDarkMode = AppTheme.isDark(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final primary = AppTheme.getPrimary(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getTimeGreeting()}, $_displayName',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.3,
                  fontFamily: 'Inter',
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _currentMonth,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Instant Theme Toggle Button (Sun/Moon)
            NeuIconButton(
              icon: isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              iconColor: isDarkMode ? Colors.amber : primary,
              size: 40,
              iconSize: 20,
              onTap: () {
                ThemeNotifier.instance.toggleTheme();
              },
            ),
            const SizedBox(width: 10),
            // Notification Bell with unread badge
            NeuIconButton(
              icon: Icons.notifications_outlined,
              iconColor: textPrimary,
              size: 40,
              iconSize: 20,
              hasBadge: _pendingCount > 0,
              onTap: _openSmsDetection,
            ),
            const SizedBox(width: 10),
            // User Avatar (Elevated Neumorphic Ring)
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                _loadHomeData();
              },
              child: NeuCard(
                isCircle: true,
                depth: 3.5,
                blur: 6.0,
                padding: const EdgeInsets.all(0),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primary,
                      fontFamily: 'Inter',
                    ),
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
    final textPrimary = AppTheme.getTextPrimary(context);
    final primary = AppTheme.getPrimary(context);
    final secondary = AppTheme.getSecondary(context);
    final dark = AppTheme.isDark(context);

    if (_pendingCount == 0 || _latestPending == null) {
      return NeuCard(
        borderRadius: 16,
        depth: 3.0,
        blur: 6.0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            NeuInset(
              borderRadius: 10,
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'All transactions synchronized',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
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
                  children: [
                    Text(
                      'Open',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: primary,
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
    final headerBg = isCredit
        ? (dark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFE6F7F0))
        : (dark ? const Color(0xFF7F1D1D).withValues(alpha: 0.35) : const Color(0xFFFFDAD6));
    final headerTextColor = isCredit ? AppTheme.getSecondary(context) : AppTheme.getError(context);
    final headerTitle = isCredit ? 'LATEST CREDIT DETECTED' : 'LATEST DEBIT DETECTED';
    final headerIcon = isCredit ? Icons.arrow_downward_rounded : Icons.flash_on_rounded;
    final amountColor = isCredit ? AppTheme.getSecondary(context) : AppTheme.getError(context);
    final confirmButtonColor = isCredit ? AppTheme.getSecondary(context) : AppTheme.getPrimary(context);
    final confirmText = isCredit ? 'Confirm Income' : 'Confirm Expense';

    return NeuCard(
      borderRadius: 18,
      depth: 4.5,
      blur: 9.0,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
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
                          NeuInset(
                            borderRadius: 12,
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              isCredit ? Icons.account_balance_wallet_rounded : p.categoryIcon,
                              color: isCredit ? AppTheme.getSecondary(context) : primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.merchant,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${p.bankSource} • ${p.paymentMode}',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: AppTheme.getTextSecondary(context),
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
                      child: NeuButton(
                        isPrimary: true,
                        color: confirmButtonColor,
                        height: 42,
                        borderRadius: 12,
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
                                backgroundColor: AppTheme.getSecondary(context),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              confirmText,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    NeuButton(
                      isPrimary: false,
                      height: 42,
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      onPressed: _openSmsDetection,
                      text: _pendingCount > 1 ? 'View All ($_pendingCount)' : 'Details',
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
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final secondary = AppTheme.getSecondary(context);
    final error = AppTheme.getError(context);

    return NeuCard(
      borderRadius: 22,
      depth: 4.5,
      blur: 9.0,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currentMonth.toUpperCase()} OVERVIEW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 19,
                color: textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total Available Balance',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            balanceStr,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.5,
              fontFamily: 'Inter',
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          // Sub metric sunken boxes: Income & Expenses
          Row(
            children: [
              // Income
              Expanded(
                child: NeuInset(
                  borderRadius: 14,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: secondary.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_downward_rounded,
                              size: 12,
                              color: secondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Income',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${_formatCurrency(_totalReceived.toInt())}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: secondary,
                          fontFamily: 'Inter',
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Expenses
              Expanded(
                child: NeuInset(
                  borderRadius: 14,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: error.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              size: 12,
                              color: error,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Expenses',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${_formatCurrency(_totalSpent.toInt())}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: error,
                          fontFamily: 'Inter',
                          fontFeatures: const [FontFeature.tabularFigures()],
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
          subtextColor: AppTheme.getTextMuted(context),
        ),
        const SizedBox(width: 8),
        _buildMetricItem(
          title: 'This Week',
          value: '₹${_formatCurrency(_weekSpent.toInt())}',
          subtext: 'Past 7 days',
          subtextColor: AppTheme.getSecondary(context),
        ),
        const SizedBox(width: 8),
        _buildMetricItem(
          title: 'This Month',
          value: '₹${_formatCurrency((_monthSpent > 0 ? _monthSpent : _totalSpent).toInt())}',
          subtext: _currentMonth,
          subtextColor: AppTheme.getTextMuted(context),
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
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return Expanded(
      child: NeuCard(
        borderRadius: 16,
        depth: 3.5,
        blur: 7.0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textSecondary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                fontFamily: 'Inter',
                fontFeatures: const [FontFeature.tabularFigures()],
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
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return NeuCard(
      borderRadius: 20,
      depth: 4.0,
      blur: 8.0,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending by Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                _totalSpent > 0 ? 'Total: ₹${_formatCurrency(_totalSpent.toInt())}' : 'No Spends',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_homeCategorySummary.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No category expenses recorded for this month.',
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
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
                  context: context,
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
    required BuildContext context,
    required IconData icon,
    required String title,
    required String amount,
    required double progress,
    Color? progressColor,
  }) {
    final primary = AppTheme.getPrimary(context);
    final textPrimary = AppTheme.getTextPrimary(context);

    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            const Spacer(),
            Text(
              amount,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
                fontFamily: 'Inter',
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        NeuInset(
          borderRadius: 6,
          height: 10,
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                progressColor ?? primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Recent Transactions Section
  Widget _buildRecentTransactionsSection(BuildContext context) {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final primary = AppTheme.getPrimary(context);
    final secondary = AppTheme.getSecondary(context);
    final error = AppTheme.getError(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
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
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentTxns.isEmpty)
          NeuCard(
            borderRadius: 16,
            depth: 2.5,
            blur: 5.0,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No transactions recorded yet.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: textSecondary,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentTxns.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final tx = _recentTxns[index];
              return NeuCard(
                borderRadius: 16,
                depth: 3.0,
                blur: 6.0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                child: Row(
                  children: [
                    NeuInset(
                      borderRadius: 12,
                      padding: const EdgeInsets.all(8),
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
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              fontFamily: 'Inter',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tx.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
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
                            color: tx.isIncome ? secondary : error,
                            fontFamily: 'Inter',
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tx.account,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.getTextMuted(context),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // + Add Expense Manually Button
  Widget _buildAddExpenseButton(BuildContext context) {
    return NeuButton(
      isPrimary: true,
      height: 50,
      borderRadius: 16,
      onPressed: _openAddExpense,
      text: 'Add Expense Manually',
      icon: Icons.add_rounded,
    );
  }
}

