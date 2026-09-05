import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedMonth = 'September 2026';
  bool _isExporting = false;

  void _handleExport() async {
    setState(() {
      _isExporting = true;
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;
    setState(() {
      _isExporting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$_selectedMonth statement downloaded (PDF)',
                style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppTheme.textPrimary,
                    size: 24,
                  ),
                  onPressed: () {},
                ),
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppTheme.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
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

  // 2. Subheader: "Monthly Pulse" + "< September 2026 >" pill selector
  Widget _buildMonthlyPulseHeader(BuildContext context) {
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
                onTap: () {
                  setState(() {
                    _selectedMonth = 'August 2026';
                  });
                },
                child: const Icon(
                  Icons.chevron_left_rounded,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _selectedMonth,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedMonth = 'September 2026';
                  });
                },
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppTheme.textSecondary,
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
                    children: const [
                      Text(
                        '₹18,450',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
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
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.trending_up_rounded,
                      color: Color(0xFFBA1A1A),
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '+8.2% vs last month',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFBA1A1A),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: const [
                  Text(
                    'Budget utilized: ',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '73%',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Smart Tip Banner (Dark Slate Gradient Card)
  Widget _buildSmartTipBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'SMART TIP',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Dining expenses peaked on weekends. Save ₹1,200 with weekly cook plans!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // 5. Expense Trend Section + Chart
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
                height: 150,
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

  // 6. Category Breakdown Section
  Widget _buildCategoryBreakdownSection() {
    final categories = [
      _CategoryBreakdownItem('Bills & Utilities', '₹5,000', '27%', 0.27, const Color(0xFF4648D4)),
      _CategoryBreakdownItem('Food & Groceries', '₹4,500', '24%', 0.24, const Color(0xFF6063EE)),
      _CategoryBreakdownItem('Other Miscellaneous', '₹3,650', '20%', 0.20, const Color(0xFF818CF8)),
      _CategoryBreakdownItem('Shopping & Retail', '₹3,200', '17%', 0.17, const Color(0xFFA5B4FC)),
      _CategoryBreakdownItem('Travel & Commute', '₹2,100', '11%', 0.11, const Color(0xFFC7D2FE)),
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Category Breakdown',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '5 Categories',
              style: TextStyle(
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
          child: Column(
            children: List.generate(categories.length, (index) {
              final item = categories[index];
              final isLast = index == categories.length - 1;

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
                            color: item.color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.amount,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 32,
                          child: Text(
                            item.percentage,
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
                        value: item.progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFF2F3FF),
                        valueColor: AlwaysStoppedAnimation<Color>(item.color),
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

  // 7. Top Spending Section
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
              'View All',
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
          child: Column(
            children: [
              _buildTopSpendingRow(
                icon: Icons.shopping_bag_outlined,
                iconColor: AppTheme.primary,
                iconBg: const Color(0xFFEEF2FF),
                title: 'Amazon India',
                subtitle: 'Shopping & Gadgets',
                amount: '₹3,200',
                meta: '4 orders',
              ),
              const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
              _buildTopSpendingRow(
                icon: Icons.restaurant_rounded,
                iconColor: const Color(0xFF006C49),
                iconBg: const Color(0xFFDCFCE7),
                title: 'Food & Dining',
                subtitle: 'Groceries & Cafes',
                amount: '₹2,850',
                meta: '12 visits',
              ),
              const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
              _buildTopSpendingRow(
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFFBA1A1A),
                iconBg: const Color(0xFFFEE2E2),
                title: 'Utility Bills',
                subtitle: 'Electricity & Wi-Fi',
                amount: '₹2,400',
                meta: 'Autopaid',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopSpendingRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String amount,
    required String meta,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
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
                    fontFamily: 'Inter',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                meta,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 8. Export Statement Button
  Widget _buildExportButton() {
    return InkWell(
      onTap: _isExporting ? null : _handleExport,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isExporting)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              const Icon(
                Icons.file_download_outlined,
                color: Colors.white,
                size: 20,
              ),
            const SizedBox(width: 8),
            Text(
              _isExporting ? 'Generating Statement...' : 'Export September Statement',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdownItem {
  final String name;
  final String amount;
  final String percentage;
  final double progress;
  final Color color;

  const _CategoryBreakdownItem(this.name, this.amount, this.percentage, this.progress, this.color);
}

// Custom Painter for Smooth Bézier Area Chart
class _ExpenseTrendChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 32.0;
    final chartWidth = size.width - leftMargin;
    final chartHeight = size.height;

    // Y Axis labels and dashed guidelines
    final yLabels = ['15k', '10k', '5k'];
    final yPositions = [chartHeight * 0.1, chartHeight * 0.45, chartHeight * 0.8];

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final dashedPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (int i = 0; i < yLabels.length; i++) {
      final y = yPositions[i];

      // Draw dashed horizontal line
      double startX = leftMargin;
      const dashWidth = 4.0;
      const dashSpace = 4.0;
      while (startX < size.width) {
        canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), dashedPaint);
        startX += dashWidth + dashSpace;
      }

      // Draw Y label
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

    // Coordinates for the trend curve across 5 points (Days 1, 7, 14, 21, 28)
    final points = [
      Offset(leftMargin, chartHeight * 0.8),
      Offset(leftMargin + chartWidth * 0.25, chartHeight * 0.65),
      Offset(leftMargin + chartWidth * 0.50, chartHeight * 0.12), // Day 14 peak
      Offset(leftMargin + chartWidth * 0.75, chartHeight * 0.38), // Dip
      Offset(leftMargin + chartWidth, chartHeight * 0.08),       // End Day 28
    ];

    // Build smooth cubic path
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // Fill area under the curve
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

    // Stroke the curve line
    final strokePaint = Paint()
      ..color = const Color(0xFF4648D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    // Draw active highlight dot at Day 14
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

