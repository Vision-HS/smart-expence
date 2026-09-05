import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'add_expense_screen.dart';
import '../../transactions/screens/sms_detection_screen.dart';
import '../../transactions/screens/transaction_details_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpenseItemModel {
  final String dateGroup;
  final String title;
  final String subtitle;
  final double amount;
  final String account;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String? badgeText;
  final Color? badgeBgColor;
  final Color? badgeTextColor;
  final bool isIncome;
  final String paymentType;
  final String monthYear; // e.g. "October 2024", "September 2024"

  _ExpenseItemModel({
    required this.dateGroup,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.account,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    this.badgeText,
    this.badgeBgColor,
    this.badgeTextColor,
    required this.isIncome,
    required this.paymentType,
    required this.monthYear,
  });
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _selectedMonth = 'October 2024';
  String _selectedFilter = 'All'; // 'All', 'Expense', 'Income', 'UPI'

  final List<String> _availableMonths = [
    'October 2024',
    'September 2024',
    'August 2024',
    'July 2024',
  ];

  final List<_ExpenseItemModel> _allTransactions = [
    // September 2024 / Sample Data for month switcher
    _ExpenseItemModel(
      dateGroup: 'TODAY',
      title: 'Amazon',
      subtitle: 'Shopping â€¢ UPI â€¢ 10:42 AM',
      amount: -1299.0,
      account: 'HDFC â€¢â€¢4021',
      icon: Icons.shopping_bag_outlined,
      iconBgColor: const Color(0xFFFEF2F2),
      iconColor: const Color(0xFFBA1A1A),
      isIncome: false,
      paymentType: 'UPI',
      monthYear: 'September 2024',
    ),
    _ExpenseItemModel(
      dateGroup: 'TODAY',
      title: 'Rahul',
      subtitle: 'Food â€¢ UPI â€¢ 09:15 AM',
      amount: -500.0,
      account: 'Google Pay',
      icon: Icons.coffee_outlined,
      iconBgColor: const Color(0xFFEAEDFF),
      iconColor: const Color(0xFF4648D4),
      isIncome: false,
      paymentType: 'UPI',
      monthYear: 'September 2024',
    ),
    _ExpenseItemModel(
      dateGroup: 'TODAY',
      title: 'Swiggy',
      subtitle: 'Food â€¢ Card â€¢ 01:20 PM',
      amount: -420.0,
      account: 'ICICI â€¢â€¢8912',
      icon: Icons.restaurant_outlined,
      iconBgColor: const Color(0xFFFEF2F2),
      iconColor: const Color(0xFFBA1A1A),
      isIncome: false,
      paymentType: 'Card',
      monthYear: 'September 2024',
    ),
    _ExpenseItemModel(
      dateGroup: 'YESTERDAY',
      title: 'Uber',
      subtitle: 'Travel â€¢ UPI â€¢ 08:20 PM',
      amount: -340.0,
      account: 'Paytm UPI',
      icon: Icons.directions_car_outlined,
      iconBgColor: const Color(0xFFEAEDFF),
      iconColor: const Color(0xFF4648D4),
      isIncome: false,
      paymentType: 'UPI',
      monthYear: 'September 2024',
    ),
    _ExpenseItemModel(
      dateGroup: 'YESTERDAY',
      title: 'Salary',
      subtitle: 'Income â€¢ Bank Transfer â€¢ 10:00 AM',
      amount: 50000.0,
      account: 'HDFC Salary',
      icon: Icons.payments_outlined,
      iconBgColor: const Color(0xFFDCFCE7),
      iconColor: const Color(0xFF006C49),
      badgeText: 'Credited',
      badgeBgColor: const Color(0xFF6CF8BB),
      badgeTextColor: const Color(0xFF005236),
      isIncome: true,
      paymentType: 'Bank Transfer',
      monthYear: 'September 2024',
    ),
  ];

  List<_ExpenseItemModel> get _monthTransactions {
    return _allTransactions.where((t) => t.monthYear == _selectedMonth).toList();
  }

  List<_ExpenseItemModel> get _filteredTransactions {
    final list = _monthTransactions;
    if (_selectedFilter == 'All') return list;
    if (_selectedFilter == 'Expense') return list.where((t) => !t.isIncome).toList();
    if (_selectedFilter == 'Income') return list.where((t) => t.isIncome).toList();
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Statement Month',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              ..._availableMonths.map((m) {
                final isSel = m == _selectedMonth;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  tileColor: isSel ? const Color(0xFFEAEDFF) : null,
                  leading: Icon(
                    Icons.calendar_month_rounded,
                    color: isSel ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                  title: Text(
                    m,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                  trailing: isSel
                      ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedMonth = m;
                    });
                    Navigator.pop(ctx);
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
      setState(() {
        _allTransactions.insert(
          0,
          _ExpenseItemModel(
            dateGroup: 'TODAY',
            title: result['merchant'] ?? 'Custom Expense',
            subtitle: '${result['category'] ?? 'General'} \u2022 ${result['payment'] ?? 'UPI'} \u2022 Just now',
            amount: -(result['amount'] as num).toDouble(),
            account: result['payment'] ?? 'Default Account',
            icon: Icons.receipt_long_outlined,
            iconBgColor: const Color(0xFFFEF2F2),
            iconColor: const Color(0xFFBA1A1A),
            isIncome: false,
            paymentType: result['payment'] ?? 'UPI',
            monthYear: _selectedMonth,
          ),
        );
      });
    }
  }

  void _openSmsDetection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SmsDetectionScreen()),
    );
    if (result != null && result is List<Map<String, dynamic>>) {
      setState(() {
        for (final item in result) {
          _allTransactions.insert(
            0,
            _ExpenseItemModel(
              dateGroup: 'TODAY',
              title: item['merchant'] ?? 'SMS Expense',
              subtitle: '${item['category'] ?? 'General'} • ${item['payment'] ?? 'UPI'} • Confirmed SMS',
              amount: -(item['amount'] as num).toDouble(),
              account: item['payment'] ?? 'Bank Account',
              icon: item['category'] == 'Food'
                  ? Icons.restaurant_outlined
                  : (item['category'] == 'Shopping'
                      ? Icons.shopping_bag_outlined
                      : Icons.receipt_long_outlined),
              iconBgColor: item['category'] == 'Food'
                  ? const Color(0xFFEAEDFF)
                  : const Color(0xFFFEF2F2),
              iconColor: item['category'] == 'Food'
                  ? const Color(0xFF4648D4)
                  : const Color(0xFFBA1A1A),
              isIncome: false,
              paymentType: item['payment'] ?? 'UPI',
              monthYear: _selectedMonth,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;
    final isEmpty = filtered.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.surface,
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
              if (isEmpty) _buildEmptyStateCard() else _buildPopulatedList(filtered),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Expenses',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: AppTheme.textPrimary,
                size: 24,
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 4),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Month & Sync Subheader
  Widget _buildMonthAndSyncHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _showMonthPicker,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEDFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _selectedMonth,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        // Sync: • Live pill badge
        GestureDetector(
          onTap: _openSmsDetection,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAEDFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sync: ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF464554),
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF006C49),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Live',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF006C49),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. Segmented Filter Tabs: All, Expense, Income, UPI
  Widget _buildSegmentedFilter() {
    final tabs = ['All', 'Expense', 'Income', 'UPI'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEDFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSel = tab == _selectedFilter;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = tab;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tab,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? AppTheme.primary : const Color(0xFF464554),
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
    return Row(
      children: [
        // Total Spent Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL SPENT',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Color(0xFF464554),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAEDFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        color: AppTheme.primary,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '\$${_totalSpent.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
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
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL RECEIVED',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Color(0xFF464554),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6CF8BB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Color(0xFF00714D),
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '\$${_totalReceived.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
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

  // 5. Empty State Card matching media_1788606697730.png
  Widget _buildEmptyStateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F3FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFF464554),
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No transactions yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your expenses will appear here automatically when SMS messages are detected, or you can add them manually.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              height: 1.45,
              color: Color(0xFF767586),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _navigateToAddExpense,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFF4648D4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Add Expense',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  // Populated list fallback if transactions exist in selected month
  Widget _buildPopulatedList(List<_ExpenseItemModel> list) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: List.generate(list.length, (index) {
          final item = list[index];
          final isLast = index == list.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailsScreen(
                        title: item.title,
                        category: item.subtitle.split('\u2022').first.trim(),
                        amount: item.amount,
                        dateTime: item.dateGroup,
                        status: item.isIncome ? 'Completed via Bank Transfer' : 'Completed via ${item.paymentType}',
                        bankAccount: item.account,
                        paymentMethod: item.paymentType,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: item.iconBgColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, color: item.iconColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Color(0xFF767586),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${item.amount > 0 ? '+' : '-'}\$${item.amount.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: item.isIncome ? const Color(0xFF006C49) : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(height: 1, thickness: 1, indent: 66, endIndent: 14, color: Color(0xFFF1F5F9)),
            ],
          );
        }),
      ),
    );
  }

  // 6. SMS Detection Banner
  Widget _buildSmsDetectionBanner(BuildContext context) {
    return GestureDetector(
      onTap: _openSmsDetection,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAEDFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.bolt_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'SMS Detection is active and listening for bank alerts.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF464554),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
