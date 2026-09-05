import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  double _amount = 0.0;
  final TextEditingController _merchantController =
      TextEditingController(text: 'Rahul');
  final TextEditingController _notesController =
      TextEditingController(text: 'Lunch with team at cafe');

  String _selectedCategory = 'Food & Dining';
  IconData _selectedCategoryIcon = Icons.restaurant_outlined;

  DateTime _selectedDate = DateTime(2026, 9, 3);
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 15);

  String _selectedPaymentMethod = 'UPI';
  final List<String> _paymentMethods = ['UPI', 'Card', 'Cash', 'NetBank'];

  @override
  void dispose() {
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addPreset(double val) {
    setState(() {
      _amount += val;
    });
  }

  void _clearAmount() {
    setState(() {
      _amount = 0.0;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _openCategoryPicker() {
    final categories = [
      {'name': 'Food & Dining', 'icon': Icons.restaurant_outlined},
      {'name': 'Shopping', 'icon': Icons.shopping_bag_outlined},
      {'name': 'Bills & Utilities', 'icon': Icons.receipt_long_outlined},
      {'name': 'Travel', 'icon': Icons.directions_car_outlined},
      {'name': 'Entertainment', 'icon': Icons.movie_outlined},
      {'name': 'Groceries', 'icon': Icons.shopping_cart_outlined},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                ...categories.map((cat) {
                  final name = cat['name'] as String;
                  final icon = cat['icon'] as IconData;
                  final isSelected = _selectedCategory == name;

                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 20, color: AppTheme.primary),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: AppTheme.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppTheme.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = name;
                        _selectedCategoryIcon = icon;
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = d.day.toString().padLeft(2, '0');
    final month = months[d.month - 1];
    return '$day $month ${d.year}';
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmountStr = _amount.toStringAsFixed(2);

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. App Bar
              _buildAppBar(context),
              const SizedBox(height: 16),

              // 2. Enter Expense Hero Module
              _buildEnterExpenseHero(formattedAmountStr),
              const SizedBox(height: 18),

              // 3. Person / Merchant
              _buildPersonMerchantSection(),
              const SizedBox(height: 16),

              // 4. Category
              _buildCategorySection(),
              const SizedBox(height: 16),

              // 5. Date & Time (2 Columns)
              _buildDateTimeSection(),
              const SizedBox(height: 16),

              // 6. Payment Method
              _buildPaymentMethodSection(),
              const SizedBox(height: 16),

              // 7. Notes (Optional)
              _buildNotesSection(),
              const SizedBox(height: 24),

              // 8. Save Expense CTA Button
              _buildSaveButton(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // App Bar: Back arrow, "Add Expense", User silhouette avatar
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
              'Add Expense',
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

  // Enter Expense Hero Card
  Widget _buildEnterExpenseHero(String formattedAmountStr) {
    final presets = [100.0, 500.0, 1000.0, 2000.0];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        children: [
          const Text(
            'ENTER EXPENSE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppTheme.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),

          // Amount Display with Currency Symbol and Blinking/Static Cursor
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '₹ ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                formattedAmountStr,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Inter',
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 3),
                width: 2.5,
                height: 34,
                color: AppTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Quick Preset Chips (+₹100, +₹500, +₹1,000, +₹2,000)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: presets.map((val) {
              final label = val >= 1000
                  ? '+₹${(val / 1000).toInt()},000'
                  : '+₹${val.toInt()}';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: InkWell(
                  onTap: () => _addPreset(val),
                  borderRadius: BorderRadius.circular(9999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Backspace / Clear button
          InkWell(
            onTap: _clearAmount,
            borderRadius: BorderRadius.circular(9999),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.backspace_outlined,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Person / Merchant Input Section
  Widget _buildPersonMerchantSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Person / Merchant',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 20,
                color: AppTheme.textPrimary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _merchantController,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Inter',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Enter merchant or person',
                    hintStyle: TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const Icon(
                Icons.badge_outlined,
                size: 20,
                color: AppTheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Category Selector Section
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _openCategoryPicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _selectedCategoryIcon,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedCategory,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Date & Time (2 Columns)
  Widget _buildDateTimeSection() {
    return Row(
      children: [
        // Date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Date',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 17,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatDate(_selectedDate),
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
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Time',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_outlined,
                        size: 17,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatTime(_selectedTime),
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Payment Method Segmented Bar
  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: _paymentMethods.map((method) {
              final isSelected = _selectedPaymentMethod == method;
              return Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = method;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0x0A000000),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      method,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Notes Section
  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes (Optional)',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                size: 20,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _notesController,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Inter',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Add note (optional)',
                    hintStyle: TextStyle(
                      color: AppTheme.textMuted,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Save Expense CTA Button
  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          final amt = _amount > 0 ? _amount : 500.0;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Saved expense: ₹${amt.toStringAsFixed(2)} for ${_merchantController.text}',
              ),
              backgroundColor: AppTheme.primary,
              duration: const Duration(seconds: 2),
            ),
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
            Icon(Icons.check_rounded, size: 20, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Save Expense',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

