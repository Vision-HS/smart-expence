import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/sms_parser_service.dart';
import '../../../shared/widgets/bottom_navigation.dart';
import '../../expenses/models/pending_sms_model.dart';
import '../../expenses/repositories/transaction_repository.dart';

class SmsDetectionScreen extends StatefulWidget {
  const SmsDetectionScreen({super.key});

  @override
  State<SmsDetectionScreen> createState() => _SmsDetectionScreenState();
}

class _SmsDetectionScreenState extends State<SmsDetectionScreen> {
  List<PendingSmsModel> _pendingTransactions = [];
  bool _isLoading = true;
  bool _isScanningInbox = false;
  final List<Map<String, dynamic>> _confirmedList = [];
  StreamSubscription<PendingSmsModel>? _smsSubscription;

  @override
  void initState() {
    super.initState();
    _loadPendingSms();
    _setupRealtimeSmsListener();
    _autoSyncInbox();
  }

  Future<void> _autoSyncInbox() async {
    try {
      final granted = await SmsParserService.instance.checkPermissions();
      if (granted) {
        final added = await SmsParserService.instance.syncInboxMessages(limit: 150);
        if (added > 0 && mounted) {
          await _loadPendingSms();
        }
      }
    } catch (_) {}
  }

  void _setupRealtimeSmsListener() {
    _smsSubscription = SmsParserService.instance.onIncomingSms.listen((newSms) {
      if (!mounted) return;
      setState(() {
        _pendingTransactions.insert(0, newSms);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text('Live SMS Detected: ₹${newSms.amount.toInt()} at ${newSms.merchant}!'),
            ],
          ),
          backgroundColor: const Color(0xFF131B2E),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    });
  }

  @override
  void dispose() {
    _smsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _scanInboxNow() async {
    setState(() {
      _isScanningInbox = true;
    });
    final added = await SmsParserService.instance.syncInboxMessages(limit: 150);
    await _loadPendingSms();
    if (!mounted) return;
    setState(() {
      _isScanningInbox = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added > 0
              ? 'Synced $added new transaction SMS alerts from inbox!'
              : 'Inbox scanned. No new transaction SMS found.',
        ),
        backgroundColor: added > 0 ? const Color(0xFF006C49) : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadPendingSms() async {
    try {
      final list = await TransactionRepository.instance.getPendingSms();
      list.sort((a, b) => b.id.compareTo(a.id));
      if (mounted) {
        setState(() {
          _pendingTransactions = list;
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

  void _confirmTransaction(PendingSmsModel tx) async {
    await TransactionRepository.instance.confirmSmsTransaction(
      tx,
      chosenCategory: tx.suggestedCategory,
      monthYear: 'September 2024',
    );
    if (!mounted) return;
    setState(() {
      _confirmedList.add({
        'merchant': tx.merchant,
        'amount': tx.amount,
        'category': tx.suggestedCategory,
        'payment': tx.paymentMode,
      });
      _pendingTransactions.removeWhere((item) => item.id == tx.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ \u20B9${tx.amount.toInt()} to ${tx.merchant} confirmed!'),
        backgroundColor: const Color(0xFF006C49),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _ignoreTransaction(PendingSmsModel tx) async {
    await TransactionRepository.instance.dismissPendingSms(tx.id);
    if (!mounted) return;
    setState(() {
      _pendingTransactions.removeWhere((item) => item.id == tx.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transaction from ${tx.merchant} ignored.'),
        backgroundColor: const Color(0xFF464554),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showCategoryPicker(PendingSmsModel tx) {
    final categories = [
      {'name': 'Food', 'icon': Icons.restaurant_rounded},
      {'name': 'Shopping', 'icon': Icons.shopping_bag_outlined},
      {'name': 'Travel', 'icon': Icons.directions_car_outlined},
      {'name': 'Entertainment', 'icon': Icons.movie_outlined},
      {'name': 'Bills', 'icon': Icons.receipt_long_outlined},
      {'name': 'Health', 'icon': Icons.medical_services_outlined},
      {'name': 'General', 'icon': Icons.category_outlined},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7,
            ),
            child: SingleChildScrollView(
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
                'Change Category',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...categories.map((c) {
                final isSel = c['name'] == tx.suggestedCategory;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  tileColor: isSel ? const Color(0xFFEAEDFF) : null,
                  leading: Icon(
                    c['icon'] as IconData,
                    color: isSel ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                  title: Text(
                    c['name'] as String,
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
                      tx.suggestedCategory = c['name'] as String;
                    });
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  },
);
  }

  void _showEditSheet(PendingSmsModel tx) {
    final merchantCtrl = TextEditingController(text: tx.merchant);
    final amountCtrl = TextEditingController(text: tx.amount.toInt().toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
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
                'Edit Transaction Details',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: merchantCtrl,
                decoration: InputDecoration(
                  labelText: 'Merchant / Payee',
                  labelStyle: const TextStyle(color: Color(0xFF464554)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.storefront_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (\u20B9)',
                  labelStyle: const TextStyle(color: Color(0xFF464554)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF464554))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4648D4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() {
                          tx.merchant = merchantCtrl.text.trim();
                          final parsedAmt = double.tryParse(amountCtrl.text.trim());
                          if (parsedAmt != null) {
                            tx.amount = parsedAmt;
                          }
                        });
                        Navigator.pop(ctx);
                        _confirmTransaction(tx);
                      },
                      child: const Text('Save & Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
              _buildSubheader(context),
              const SizedBox(height: 16),
              _buildAiSmartCaptureBanner(),
              const SizedBox(height: 16),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                )
              else if (_pendingTransactions.isEmpty)
                _buildAllCaughtUpState()
              else
                ..._pendingTransactions.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildTransactionCard(entry.value, isFirst: entry.key == 0),
                    )),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 1, // Expenses tab selected
        onTap: (index) {
          Navigator.pop(context, _confirmedList.isNotEmpty ? _confirmedList : null);
        },
      ),
    );
  }

  // 1. Top Bar: "Expenses" + Notification bell + User avatar
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

  // 2. Subheader: Back arrow + "New Transactions" / "Smart SMS Sync" + Pending pill
  Widget _buildSubheader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.pop(context, _confirmedList.isNotEmpty ? _confirmedList : null);
              },
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.arrow_back,
                  color: AppTheme.textPrimary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'New Transactions',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Smart SMS Sync',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF767586),
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            InkWell(
              onTap: _isScanningInbox ? null : _scanInboxNow,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isScanningInbox)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                      )
                    else
                      const Icon(Icons.sync_rounded, size: 14, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      _isScanningInbox ? 'Scanning...' : 'Scan Inbox',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Pending Count Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB61722),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_pendingTransactions.length} Pending',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB61722),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 3. AI Smart Capture Banner
  Widget _buildAiSmartCaptureBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E7FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF4648D4),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Smart Capture',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Automatically detected from bank & UPI SMS. Review and confirm to instantly update your ledger.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    height: 1.38,
                    color: Color(0xFF464554),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Pending Transaction Card with Red Accent Stripe
  Widget _buildTransactionCard(PendingSmsModel tx, {bool isFirst = false}) {
    final amtFormatted = tx.amount >= 1000
        ? _formatNumber(tx.amount)
        : (tx.amount == tx.amount.roundToDouble()
            ? tx.amount.toInt().toString()
            : tx.amount.toStringAsFixed(2));

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFirst ? const Color(0xFFDA3437) : const Color(0xFFE2E8F0),
            width: isFirst ? 2 : 1,
          ),
          boxShadow: isFirst
              ? const [
                  BoxShadow(
                    color: Color(0x1ADA3437),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Solid Red Left Edge Stripe (6px for first, 4px for others)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: isFirst ? 6 : 4,
              child: Container(
                color: const Color(0xFFDA3437),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: "LATEST DEBIT TRANSACTION" (if first) vs "New transaction detected" + Timestamp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isFirst ? Icons.flash_on_rounded : Icons.sms_outlined,
                            size: 16,
                            color: const Color(0xFFDA3437),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isFirst ? 'LATEST DEBIT TRANSACTION' : 'New transaction detected',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: isFirst ? FontWeight.w800 : FontWeight.w600,
                              color: const Color(0xFFDA3437),
                              letterSpacing: isFirst ? 0.3 : 0,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        tx.timeAgo,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: isFirst ? FontWeight.w700 : FontWeight.w500,
                          color: isFirst ? const Color(0xFFDA3437) : const Color(0xFF767586),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Row 2: Merchant Avatar + Name & Time + Amount & DEBIT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: tx.merchantIconBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              tx.merchantIcon,
                              color: tx.merchantIconColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.merchant,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${tx.paymentMode} \u2022 ${tx.timeString}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF767586),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '-\u20B9$amtFormatted',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB61722),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'DEBIT',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF767586),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Row 3: Suggested Category Pill
                  GestureDetector(
                    onTap: () => _showCategoryPicker(tx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAEDFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tx.categoryIcon,
                            size: 14,
                            color: const Color(0xFF4648D4),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Suggested: ${tx.suggestedCategory}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4648D4),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: Color(0xFF4648D4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Row 4: Bank SMS Detection Source
                  Row(
                    children: [
                      Icon(
                        tx.bankIcon,
                        size: 14,
                        color: const Color(0xFF767586),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tx.bankSource,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF767586),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Row 5: Action Buttons (Confirm + Edit or Confirm + Ignore)
                  Row(
                    children: [
                      // Confirm Button (Blue)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _confirmTransaction(tx),
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4648D4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Confirm',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Secondary Button: Edit (for Card 1) or Ignore (for Card 2)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!tx.isSecondCard) {
                              _showEditSheet(tx);
                            } else {
                              _ignoreTransaction(tx);
                            }
                          },
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: !tx.isSecondCard ? const Color(0xFFEAEDFF) : const Color(0xFFF2F3FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  !tx.isSecondCard ? Icons.edit_outlined : Icons.close_rounded,
                                  color: !tx.isSecondCard ? const Color(0xFF131B2E) : const Color(0xFF464554),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  !tx.isSecondCard ? 'Edit' : 'Ignore',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: !tx.isSecondCard ? const Color(0xFF131B2E) : const Color(0xFF464554),
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }

  // 5. Empty State when all pending transactions are confirmed or dismissed
  Widget _buildAllCaughtUpState() {
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
              color: Color(0xFFEAEDFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.done_all_rounded,
              color: Color(0xFF4648D4),
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No pending SMS transactions. Auto-Sync is actively monitoring incoming bank & UPI alerts in real-time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF767586),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _isScanningInbox ? null : _scanInboxNow,
                icon: _isScanningInbox
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                      )
                    : const Icon(Icons.sync_rounded, size: 16, color: AppTheme.primary),
                label: Text(
                  _isScanningInbox ? 'Scanning...' : 'Scan Inbox',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFC0C1FF)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _confirmedList.isNotEmpty ? _confirmedList : null);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4648D4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text(
                  'Back to Expenses',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(double num) {
    // 1299 -> "1,299"
    final intVal = num.toInt();
    final str = intVal.toString();
    if (str.length <= 3) return str;
    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    return '$rest,$lastThree';
  }
}
