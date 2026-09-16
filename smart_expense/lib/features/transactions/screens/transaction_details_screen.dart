import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../expenses/models/transaction_model.dart';
import '../../expenses/repositories/transaction_repository.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final TransactionModel? transaction;
  final int? id;
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
  final String? notes;

  const TransactionDetailsScreen({
    super.key,
    this.transaction,
    this.id,
    this.title = 'Expense',
    this.isVerified = true,
    this.category = 'Food & Dining',
    this.amount = -500.00,
    this.status = 'Completed',
    this.paymentMethod = 'UPI',
    this.dateTime = 'Recent',
    this.upiId = 'upi@bank',
    this.bankAccount = 'Account',
    this.referenceId = '123456789012',
    this.expenseSource = 'Verified SMS',
    this.bankAlertBody = '',
    this.notes,
  });

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  late int? _id;
  late String _title;
  late double _amount;
  late String _category;
  late String _paymentMethod;
  late String _bankAccount;
  late String _dateTime;
  late String _status;
  late String _referenceId;
  late String _bankAlertBody;
  late String _notes;
  late bool _isIncome;
  bool _hasChanges = false;

  final List<String> _categoryOptions = [
    'Food & Dining',
    'Shopping',
    'Bills & Utilities',
    'Travel',
    'Entertainment',
    'Health',
    'Education',
    'Groceries',
    'Fuel',
    'Salary',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _id = t?.id ?? widget.id;
    _title = t?.title ?? widget.title;
    _amount = t?.amount ?? widget.amount;
    _category = t?.category ?? widget.category;
    _paymentMethod = t?.paymentType ?? widget.paymentMethod;
    _bankAccount = t?.account ?? widget.bankAccount;
    _dateTime = t != null ? t.dateGroup : widget.dateTime;
    _isIncome = t?.isIncome ?? (_amount > 0);
    _status = widget.status;
    _referenceId = widget.referenceId;
    _bankAlertBody = t?.rawSms ?? widget.bankAlertBody;
    _notes = t?.notes ?? widget.notes ?? '';
  }

  void _shareTransaction() {
    final text = '''
Smart Expense Record:
• Merchant / Payee: $_title
• Amount: ₹${_amount.abs().toStringAsFixed(2)} (${_isIncome ? 'Credited' : 'Debited'})
• Category: $_category
• Payment Method: $_paymentMethod ($_bankAccount)
• Date: $_dateTime
• Reference: $_referenceId
${_notes.isNotEmpty ? '• Notes: $_notes\n' : ''}Status: Verified Offline
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Transaction details copied to clipboard!', style: TextStyle(fontFamily: 'Inter')),
          ],
        ),
        backgroundColor: const Color(0xFF006C49),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFBA1A1A)),
            SizedBox(width: 8),
            Text('Delete Transaction', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "$_title (₹${_amount.abs().toStringAsFixed(2)})" from your ledger?',
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              if (_id != null) {
                await TransactionRepository.instance.deleteTransaction(_id!);
              }
              if (!mounted) return;
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Transaction deleted from ledger'),
                  backgroundColor: Color(0xFFBA1A1A),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showEditSheet() {
    final titleCtrl = TextEditingController(text: _title);
    final amountCtrl = TextEditingController(text: _amount.abs().toStringAsFixed(2));
    final notesCtrl = TextEditingController(text: _notes);
    String selectedCat = _categoryOptions.contains(_category) ? _category : _categoryOptions.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.edit_outlined, color: AppTheme.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Edit Transaction',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Merchant / Payee',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCat,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.category_outlined, size: 20),
                ),
                items: _categoryOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedCat = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.notes_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(sheetCtx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final newTitle = titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : _title;
                        final newAmtVal = double.tryParse(amountCtrl.text.trim()) ?? _amount.abs();
                        final newNotes = notesCtrl.text.trim();
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(sheetCtx);

                        if (_id != null) {
                          final updated = TransactionModel(
                            id: _id,
                            title: newTitle,
                            amount: _isIncome ? newAmtVal : -newAmtVal,
                            category: selectedCat,
                            dateTime: widget.transaction?.dateTime ?? DateTime.now().toIso8601String(),
                            account: _bankAccount,
                            paymentType: _paymentMethod,
                            isIncome: _isIncome,
                            monthYear: widget.transaction?.monthYear ?? TransactionModel.formatMonthYear(DateTime.now()),
                            rawSms: _bankAlertBody,
                            notes: newNotes,
                          );
                          await TransactionRepository.instance.updateTransaction(updated);
                        }

                        if (!mounted) return;
                        setState(() {
                          _title = newTitle;
                          _amount = _isIncome ? newAmtVal : -newAmtVal;
                          _category = selectedCat;
                          _notes = newNotes;
                          _hasChanges = true;
                        });
                        nav.pop();

                        messenger.showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('✓ Transaction updated successfully!', style: TextStyle(fontFamily: 'Inter')),
                              ],
                            ),
                            backgroundColor: const Color(0xFF006C49),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSplitBillSheet() {
    int count = 2;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final perPerson = _amount.abs() / count;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.group_add_outlined, color: AppTheme.primary, size: 22),
                    SizedBox(width: 8),
                    Text('Split Bill Calculator', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Total: ₹${_amount.abs().toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 28, color: AppTheme.primary),
                      onPressed: count > 2 ? () => setModalState(() => count--) : null,
                    ),
                    const SizedBox(width: 12),
                    Text('$count People', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 28, color: AppTheme.primary),
                      onPressed: count < 20 ? () => setModalState(() => count++) : null,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFF2F3FF), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      const Text('Each Person Pays', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text('₹${perPerson.toStringAsFixed(2)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final splitText = 'Split bill for $_title (Total ₹${_amount.abs().toStringAsFixed(2)}): ₹${perPerson.toStringAsFixed(2)} each between $count friends.';
                      Clipboard.setData(ClipboardData(text: splitText));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Split summary copied to clipboard!'),
                          backgroundColor: Color(0xFF006C49),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                    label: const Text('Copy Split Breakdown', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddReceiptSheet() {
    final noteCtrl = TextEditingController(text: _notes);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: AppTheme.primary, size: 22),
                SizedBox(width: 8),
                Text('Add Receipt / Bill Note', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter invoice number, bill item details, or tax notes...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final text = noteCtrl.text.trim();
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(ctx);
                  if (_id != null) {
                    final updated = TransactionModel(
                      id: _id,
                      title: _title,
                      amount: _amount,
                      category: _category,
                      dateTime: widget.transaction?.dateTime ?? DateTime.now().toIso8601String(),
                      account: _bankAccount,
                      paymentType: _paymentMethod,
                      isIncome: _isIncome,
                      monthYear: widget.transaction?.monthYear ?? TransactionModel.formatMonthYear(DateTime.now()),
                      rawSms: _bankAlertBody,
                      notes: text,
                    );
                    await TransactionRepository.instance.updateTransaction(updated);
                  }
                  if (!mounted) return;
                  setState(() {
                    _notes = text;
                    _hasChanges = true;
                  });
                  nav.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('✓ Receipt note attached!'),
                      backgroundColor: Color(0xFF006C49),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Save Receipt Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = (_amount < 0 ? '-₹' : '+₹') +
        _amount.abs().toStringAsFixed(2).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
            );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
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
                if (_bankAlertBody.isNotEmpty) ...[
                  _buildBankAlertCard(),
                  const SizedBox(height: 24),
                ],

                // 7. Bottom Actions: Edit & Delete
                _buildBottomButtons(context),
                const SizedBox(height: 16),
              ],
            ),
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
              icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 24),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.pop(context, _hasChanges),
            ),
            const SizedBox(width: 14),
            Text(
              _isIncome ? 'Income Details' : 'Expense Details',
              style: const TextStyle(
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
          onTap: _shareTransaction,
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
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _isIncome ? const Color(0xFFE6F7F0) : AppTheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isIncome ? Icons.account_balance_wallet_outlined : Icons.restaurant_outlined,
              size: 26,
              color: _isIncome ? const Color(0xFF006C49) : AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              if (widget.isVerified) ...[
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

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              _category,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(height: 14),

          Text(
            formattedAmount,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: _amount < 0
                  ? const Color(0xFFBA1A1A)
                  : const Color(0xFF006C49),
              fontFamily: 'Inter',
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

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
                  _status,
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
          child: InkWell(
            onTap: _showAddReceiptSheet,
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
                      children: [
                        const Text(
                          'Add receipt',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _notes.isNotEmpty ? 'Note added' : 'Attach note',
                          style: const TextStyle(
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
        ),
        const SizedBox(width: 10),

        // Split Bill
        Expanded(
          child: InkWell(
            onTap: _showSplitBillSheet,
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
          _buildAttributeRow(label: 'Payment Method', value: _paymentMethod),
          _buildDivider(),
          _buildAttributeRow(label: 'Date & Time', value: _dateTime),
          _buildDivider(),
          _buildAttributeRow(label: 'Bank Account', value: _bankAccount),
          _buildDivider(),
          _buildAttributeRow(
            label: 'Reference ID (UTR)',
            rightWidget: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _referenceId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied Reference ID $_referenceId'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _referenceId,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.copy_rounded, size: 14, color: AppTheme.primary),
                ],
              ),
            ),
          ),
          if (_notes.isNotEmpty) ...[
            _buildDivider(),
            _buildAttributeRow(label: 'Notes', value: _notes),
          ],
        ],
      ),
    );
  }

  Widget _buildAttributeRow({
    required String label,
    String? value,
    Widget? rightWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          rightWidget ??
              Text(
                value ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: AppTheme.border);
  }

  // Original Bank Alert Card
  Widget _buildBankAlertCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.mark_email_read_outlined, size: 16, color: AppTheme.textSecondary),
              SizedBox(width: 6),
              Text(
                'ORIGINAL BANK ALERT',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.8,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _bankAlertBody,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Inter',
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
              onPressed: _showEditSheet,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppTheme.surface,
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.border, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_outlined, size: 18, color: AppTheme.textPrimary),
                  SizedBox(width: 6),
                  Text('Edit', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
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
              onPressed: _showDeleteConfirmation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFDAD6),
                foregroundColor: const Color(0xFFBA1A1A),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFBA1A1A)),
                  SizedBox(width: 6),
                  Text('Delete', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
