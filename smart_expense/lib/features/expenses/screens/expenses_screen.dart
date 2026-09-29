import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/neumorphic/neu_card.dart';
import '../../../core/widgets/neumorphic/neu_inset.dart';
import '../../../core/widgets/neumorphic/neu_button.dart';
import '../../../core/widgets/neumorphic/neu_icon_button.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';
import 'add_expense_screen.dart';
import '../../transactions/screens/sms_detection_screen.dart';
import '../../transactions/screens/transaction_details_screen.dart';
import '../../settings/screens/profile_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _selectedMonth = TransactionModel.formatMonthYear(DateTime.now());
  String _selectedFilter = 'All'; // 'All', 'Expense', 'Income', 'UPI'

  List<String> _availableMonths = [
    TransactionModel.formatMonthYear(DateTime.now()),
  ];

  List<TransactionModel> _monthTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      await TransactionRepository.instance.syncAndFixTransactionMonths();
      final months = await TransactionRepository.instance.getDistinctMonths();
      String monthToUse = _selectedMonth;
      if (months.isNotEmpty && !months.contains(_selectedMonth)) {
        monthToUse = months.first;
      }
      final list = await TransactionRepository.instance.getTransactionsByMonth(monthToUse);
      if (mounted) {
        setState(() {
          if (months.isNotEmpty) {
            _availableMonths = months;
          }
          _selectedMonth = monthToUse;
          _monthTransactions = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int get _debitCount => _monthTransactions.where((t) => !t.isIncome).length;
  int get _creditCount => _monthTransactions.where((t) => t.isIncome).length;

  String _formatCurrency(double val) {
    return val.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  List<TransactionModel> get _filteredTransactions {
    final list = _monthTransactions;
    if (_selectedFilter == 'All') return list;
    if (_selectedFilter == 'Expense' || _selectedFilter == 'Debited') return list.where((t) => !t.isIncome).toList();
    if (_selectedFilter == 'Income' || _selectedFilter == 'Credited') return list.where((t) => t.isIncome).toList();
    if (_selectedFilter == 'UPI') return list.where((t) => t.paymentType == 'UPI').toList();
    return list;
  }

  double get _totalSpent {
    final list = _monthTransactions.where((t) => !t.isIncome);
    return list.fold(0.0, (sum, t) => sum + t.amount.abs());
  }

  double get _totalReceived {
    final list = _monthTransactions.where((t) => t.isIncome);
    return list.fold(0.0, (sum, t) => sum + t.amount);
  }

  void _showMonthPicker() {
    final surfaceColor = AppTheme.getSurface(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final primary = AppTheme.getPrimary(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Statement Month',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              ..._availableMonths.map((m) {
                final isSel = m == _selectedMonth;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: isSel ? primary.withValues(alpha: 0.12) : null,
                  leading: Icon(
                    Icons.calendar_month_rounded,
                    color: isSel ? primary : textSecondary,
                  ),
                  title: Text(
                    m,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? primary : textPrimary,
                    ),
                  ),
                  trailing: isSel
                      ? Icon(Icons.check_rounded, color: primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedMonth = m;
                      _isLoading = true;
                    });
                    Navigator.pop(ctx);
                    _loadTransactions();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _navigateToAddExpense() async {
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
      _selectedMonth = TransactionModel.formatMonthYear(date);
      _loadTransactions();
    }
  }

  void _openSmsDetection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SmsDetectionScreen()),
    );
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;
    final isEmpty = filtered.isEmpty;
    final canvasColor = AppTheme.getCanvas(context);
    final primary = AppTheme.getPrimary(context);

    return Scaffold(
      backgroundColor: canvasColor,
      floatingActionButton: NeuCard(
        borderRadius: 28,
        depth: 4.5,
        blur: 9.0,
        color: primary,
        padding: EdgeInsets.zero,
        onTap: _navigateToAddExpense,
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Center(
            child: Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildTopBar(context),
              const SizedBox(height: 16),
              _buildMonthAndSyncHeader(context),
              const SizedBox(height: 16),
              _buildSegmentedFilter(),
              const SizedBox(height: 16),
              _buildMetricCards(),
              const SizedBox(height: 16),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: primary)),
                )
              else if (isEmpty)
                _buildEmptyStateCard()
              else
                _buildPopulatedList(filtered),
              const SizedBox(height: 16),
              _buildSmsDetectionBanner(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Top Bar: "Expenses" title + Notification bell + User avatar
  Widget _buildTopBar(BuildContext context) {
    final textPrimary = AppTheme.getTextPrimary(context);
    final primary = AppTheme.getPrimary(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Expenses',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        Row(
          children: [
            NeuIconButton(
              icon: Icons.notifications_none_rounded,
              size: 40,
              iconSize: 20,
              onTap: _openSmsDetection,
            ),
            const SizedBox(width: 10),
            NeuCard(
              borderRadius: 20,
              depth: 3.5,
              blur: 6.0,
              padding: EdgeInsets.zero,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Month & Sync Subheader
  Widget _buildMonthAndSyncHeader(BuildContext context) {
    final primary = AppTheme.getPrimary(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        NeuCard(
          borderRadius: 14,
          depth: 3.0,
          blur: 6.0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onTap: _showMonthPicker,
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedMonth,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
        // Sync: • Live pill badge
        GestureDetector(
          onTap: _openSmsDetection,
          child: NeuInset(
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sync: ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00B074),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Live',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00B074),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. Segmented Filter Tabs: All, Debited, Credited, UPI
  Widget _buildSegmentedFilter() {
    final tabs = ['All', 'Debited', 'Credited', 'UPI'];
    final primary = AppTheme.getPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return NeuInset(
      borderRadius: 14,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: tabs.map((tab) {
          final isSel = tab == _selectedFilter;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedFilter = tab;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? AppTheme.getSurface(context) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSel
                      ? AppTheme.neuElevation(context, depth: 2.5, blur: 5.0)
                      : null,
                ),
                child: Center(
                  child: Text(
                    tab,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? primary : textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 4. Dual Metric Cards: TOTAL SPENT & TOTAL RECEIVED
  Widget _buildMetricCards() {
    final textSecondary = AppTheme.getTextSecondary(context);
    final primary = AppTheme.getPrimary(context);

    return Row(
      children: [
        // Total Spent Card
        Expanded(
          child: NeuCard(
            borderRadius: 18,
            depth: 4.0,
            blur: 8.0,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SPENT ($_debitCount)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: textSecondary,
                      ),
                    ),
                    NeuInset(
                      borderRadius: 8,
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.arrow_downward_rounded,
                        color: primary,
                        size: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '₹${_formatCurrency(_totalSpent)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF4444),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Total Received Card
        Expanded(
          child: NeuCard(
            borderRadius: 18,
            depth: 4.0,
            blur: 8.0,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RECEIVED ($_creditCount)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: textSecondary,
                      ),
                    ),
                    NeuInset(
                      borderRadius: 8,
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Color(0xFF10B981),
                        size: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '₹${_formatCurrency(_totalReceived)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 5. Empty State Card
  Widget _buildEmptyStateCard() {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return NeuCard(
      borderRadius: 20,
      depth: 4.0,
      blur: 8.0,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        children: [
          NeuInset(
            borderRadius: 32,
            padding: const EdgeInsets.all(16),
            child: Icon(
              Icons.receipt_long_outlined,
              color: textSecondary,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your expenses will appear here automatically when SMS messages are detected, or you can add them manually.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.45,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          NeuButton(
            isPrimary: true,
            height: 46,
            borderRadius: 14,
            onPressed: _navigateToAddExpense,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Add Expense',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Populated list fallback if transactions exist in selected month
  Widget _buildPopulatedList(List<TransactionModel> list) {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return NeuCard(
      borderRadius: 20,
      depth: 4.0,
      blur: 8.0,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: List.generate(list.length, (index) {
          final item = list[index];
          final isLast = index == list.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailsScreen(
                        transaction: item,
                        id: item.id,
                        title: item.title,
                        category: item.category,
                        amount: item.amount,
                        dateTime: item.dateGroup,
                        status: item.isIncome ? 'Completed via Bank Transfer' : 'Completed via ${item.paymentType}',
                        bankAccount: item.account,
                        paymentMethod: item.paymentType,
                        expenseSource: item.rawSms != null ? 'Verified SMS' : 'Manual Entry',
                      ),
                    ),
                  );
                  if (res == true) {
                    _loadTransactions();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      NeuInset(
                        borderRadius: 12,
                        padding: const EdgeInsets.all(10),
                        child: Icon(item.icon, color: item.iconColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${item.amount > 0 ? '+' : '-'}₹${item.amount.abs().toStringAsFixed(0)}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: item.isIncome
                              ? const Color(0xFF10B981)
                              : (AppTheme.isDark(context) ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 66,
                  endIndent: 14,
                  color: AppTheme.isDark(context)
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                ),
            ],
          );
        }),
      ),
    );
  }

  // 6. SMS Detection Banner
  Widget _buildSmsDetectionBanner(BuildContext context) {
    final primary = AppTheme.getPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return GestureDetector(
      onTap: _openSmsDetection,
      child: NeuCard(
        borderRadius: 16,
        depth: 3.0,
        blur: 6.0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            NeuInset(
              borderRadius: 8,
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.bolt_rounded,
                color: primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'SMS Detection is active and listening for bank alerts.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
