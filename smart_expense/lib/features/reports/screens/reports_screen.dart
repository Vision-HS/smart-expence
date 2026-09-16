import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../expenses/models/transaction_model.dart';
import '../../expenses/repositories/transaction_repository.dart';
import '../../transactions/screens/sms_detection_screen.dart';
import '../../settings/screens/profile_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedMonth = '';
  List<String> _availableMonths = [];
  double _totalSpent = 0.0;
  double _totalReceived = 0.0;
  List<Map<String, dynamic>> _categorySummary = [];
  List<TransactionModel> _topTransactions = [];
  bool _isLoading = true;
  bool _isExporting = false;

  final List<Color> _palette = [
    const Color(0xFF4648D4),
    const Color(0xFF6063EE),
    const Color(0xFF818CF8),
    const Color(0xFFA5B4FC),
    const Color(0xFFC7D2FE),
    const Color(0xFF006C49),
    const Color(0xFF22C55E),
    const Color(0xFFEAB308),
    const Color(0xFFF97316),
    const Color(0xFFEC4899),
  ];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    try {
      final months = await TransactionRepository.instance.getDistinctMonths();
      final currentMonth = _selectedMonth.isNotEmpty && months.contains(_selectedMonth)
          ? _selectedMonth
          : (months.isNotEmpty ? months.first : TransactionModel.formatMonthYear(DateTime.now()));

      final summary = await TransactionRepository.instance.getMonthSpendSummary(currentMonth);
      final cats = await TransactionRepository.instance.getCategorySpendSummary(currentMonth);
      final top = await TransactionRepository.instance.getTopSpendingTransactions(currentMonth, limit: 5);

      if (mounted) {
        setState(() {
          _availableMonths = months;
          _selectedMonth = currentMonth;
          _totalSpent = summary['spent'] ?? 0.0;
          _totalReceived = summary['received'] ?? 0.0;
          _categorySummary = cats;
          _topTransactions = top;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _previousMonth() {
    if (_availableMonths.isEmpty) return;
    final idx = _availableMonths.indexOf(_selectedMonth);
    if (idx < _availableMonths.length - 1) {
      setState(() {
        _selectedMonth = _availableMonths[idx + 1];
        _isLoading = true;
      });
      _loadReportData();
    }
  }

  void _nextMonth() {
    if (_availableMonths.isEmpty) return;
    final idx = _availableMonths.indexOf(_selectedMonth);
    if (idx > 0) {
      setState(() {
        _selectedMonth = _availableMonths[idx - 1];
        _isLoading = true;
      });
      _loadReportData();
    }
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);

    try {
      final txs = await TransactionRepository.instance.getTransactionsByMonth(_selectedMonth);

      final buffer = StringBuffer();
      buffer.writeln('ID,Date,Merchant,Amount,Category,Type,Account,PaymentMode,Notes');
      for (final t in txs) {
        final amt = t.amount.abs().toStringAsFixed(2);
        final type = t.isIncome ? 'Credit' : 'Debit';
        final cleanTitle = t.title.replaceAll(',', ' ');
        final cleanNotes = (t.notes ?? '').replaceAll(',', ' ');
        buffer.writeln('${t.id ?? ''},${t.dateTime},$cleanTitle,$amt,${t.category},$type,${t.account},${t.paymentType},$cleanNotes');
      }

      await Clipboard.setData(ClipboardData(text: buffer.toString()));

      if (!mounted) return;
      setState(() => _isExporting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✓ $_selectedMonth CSV report (${txs.length} transactions) copied to clipboard!',
                  style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF006C49),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _formatCurrency(double val) {
    return val.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReportData,
          color: AppTheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildTopBar(context),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: LinearProgressIndicator(minHeight: 2, color: AppTheme.primary),
                  )
                else
                  const SizedBox(height: 8),
                const SizedBox(height: 8),
                _buildMonthlyPulseHeader(context),
                const SizedBox(height: 14),
                _buildTotalSpendingCard(),
                const SizedBox(height: 14),
                _buildSmartTipBanner(),
                const SizedBox(height: 20),
                _buildExpenseTrendSection(),
                const SizedBox(height: 20),
                _buildCategoryBreakdownSection(),
                const SizedBox(height: 20),
                _buildTopSpendingSection(),
                const SizedBox(height: 20),
                _buildExportButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. Top Bar: "Reports" title + notification bell + user avatar
  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Reports',
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SmsDetectionScreen()),
                );
              },
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
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
            ),
          ],
        ),
      ],
    );
  }

  // 2. Subheader: "Monthly Pulse" + "< Month >" pill selector
  Widget _buildMonthlyPulseHeader(BuildContext context) {
    final currentIdx = _availableMonths.indexOf(_selectedMonth);
    final hasPrev = currentIdx < _availableMonths.length - 1;
    final hasNext = currentIdx > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            Icon(
              Icons.show_chart_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Monthly Pulse',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: hasPrev ? _previousMonth : null,
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 18,
                  color: hasPrev ? AppTheme.textSecondary : AppTheme.border,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _selectedMonth.isNotEmpty ? _selectedMonth : 'Loading...',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: hasNext ? _nextMonth : null,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: hasNext ? AppTheme.textSecondary : AppTheme.border,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. Total Spending Hero Card
  Widget _buildTotalSpendingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Spending',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${_formatCurrency(_totalSpent)}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        '.00',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_downward_rounded,
                      size: 13,
                      color: Color(0xFF006C49),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Income: ₹${_formatCurrency(_totalReceived)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF006C49),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Net: ₹${_formatCurrency(_totalReceived - _totalSpent)}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: (_totalReceived - _totalSpent) >= 0 ? const Color(0xFF006C49) : const Color(0xFFBA1A1A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Smart Tip Banner
  Widget _buildSmartTipBanner() {
    final highestCat = _categorySummary.isNotEmpty ? _categorySummary.first['category'] : 'daily expenses';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD2D9F4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 13,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: Color(0xFF334155),
                  height: 1.35,
                ),
                children: [
                  const TextSpan(
                    text: 'Smart Insight: ',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary),
                  ),
                  TextSpan(
                    text: _totalSpent > 0
                        ? 'Highest outflow this month is in $highestCat. Review subscriptions to save.'
                        : 'No expenses tracked yet for this month. Incoming SMS will reflect here automatically.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Expense Trend Section
  Widget _buildExpenseTrendSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Expense Trend',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Daily Outflow',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 140,
                width: double.infinity,
                child: CustomPaint(
                  painter: _ExpenseTrendChartPainter(),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Day 1', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppTheme.textSecondary)),
                    Text('Day 7', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppTheme.textSecondary)),
                    Text('Day 14', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                    Text('Day 21', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppTheme.textSecondary)),
                    Text('Day 28', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 6. Category Breakdown Section (Fully Dynamic)
  Widget _buildCategoryBreakdownSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Category Breakdown',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '${_categorySummary.length} Categories',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: _categorySummary.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No expense categories recorded for this month',
                      style: TextStyle(fontFamily: 'Inter', color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              : Column(
                  children: List.generate(_categorySummary.length, (index) {
                    final item = _categorySummary[index];
                    final catName = item['category']?.toString() ?? 'Other';
                    final totalVal = (item['total'] as num?)?.toDouble() ?? 0.0;
                    final pct = _totalSpent > 0 ? (totalVal / _totalSpent) : 0.0;
                    final pctStr = '${(pct * 100).toInt()}%';
                    final color = _palette[index % _palette.length];
                    final isLast = index == _categorySummary.length - 1;

                    return Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 14.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                catName,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '₹${_formatCurrency(totalVal)}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 34,
                                child: Text(
                                  pctStr,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pct.clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: const Color(0xFFF2F3FF),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
        ),
      ],
    );
  }

  // 7. Top Spending Section (Fully Dynamic)
  Widget _buildTopSpendingSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Top Spending',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Highest Outflow',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: _topTransactions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No spending records found in this statement period',
                      style: TextStyle(fontFamily: 'Inter', color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              : Column(
                  children: List.generate(_topTransactions.length, (index) {
                    final tx = _topTransactions[index];
                    final isLast = index == _topTransactions.length - 1;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: tx.iconBgColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(tx.icon, color: tx.iconColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.title,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${tx.category} • ${tx.account}',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '-₹${_formatCurrency(tx.amount.abs())}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFBA1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isLast)
                          const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
                      ],
                    );
                  }),
                ),
        ),
      ],
    );
  }

  // 8. Export Statement Button
  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _isExporting ? null : _handleExport,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isExporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.file_download_outlined,
                    color: AppTheme.primary,
                    size: 19,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Export Statement (CSV)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ExpenseTrendChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 32.0;
    final chartWidth = size.width - leftMargin;
    final chartHeight = size.height;

    final dashedPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    final yLabels = ['₹2k', '₹1k', '₹0'];
    final yPositions = [0.0, chartHeight * 0.5, chartHeight];
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < yLabels.length; i++) {
      final y = yPositions[i];
      double startX = leftMargin;
      const dashWidth = 4.0;
      const dashSpace = 4.0;
      while (startX < size.width) {
        canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), dashedPaint);
        startX += dashWidth + dashSpace;
      }

      textPainter.text = TextSpan(
        text: yLabels[i],
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          color: Color(0xFF94A3B8),
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    final points = [
      Offset(leftMargin, chartHeight * 0.8),
      Offset(leftMargin + chartWidth * 0.25, chartHeight * 0.65),
      Offset(leftMargin + chartWidth * 0.50, chartHeight * 0.15),
      Offset(leftMargin + chartWidth * 0.75, chartHeight * 0.40),
      Offset(leftMargin + chartWidth, chartHeight * 0.10),
    ];

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, chartHeight);
    fillPath.lineTo(points.first.dx, chartHeight);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF4648D4).withValues(alpha: 0.22),
        const Color(0xFF4648D4).withValues(alpha: 0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(leftMargin, 0, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = const Color(0xFF4648D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    final day14Point = points[2];
    final outerRingPaint = Paint()
      ..color = const Color(0xFF4648D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final innerFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(day14Point, 6, innerFillPaint);
    canvas.drawCircle(day14Point, 6, outerRingPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
