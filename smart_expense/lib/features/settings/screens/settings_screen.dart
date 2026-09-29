import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/neumorphic/neu_card.dart';
import '../../../core/widgets/neumorphic/neu_inset.dart';
import '../../../core/widgets/neumorphic/neu_switch.dart';
import '../../../core/widgets/neumorphic/neu_icon_button.dart';
import '../../categories/screens/categories_screen.dart';
import '../../expenses/repositories/transaction_repository.dart';
import '../../transactions/screens/sms_detection_screen.dart';
import 'automatic_detection_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const SettingsScreen({super.key, this.onBack});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _smsDetection = true;

  void _showDeleteConfirmation() {
    final surfaceColor = AppTheme.getSurface(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(
              'Delete All Data?',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'This action will permanently purge all transactions and pending SMS alerts from this device. This cannot be undone.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            height: 1.4,
            color: textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              await TransactionRepository.instance.clearAllData();
              nav.pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('✓ All local transaction records permanently purged.'),
                  backgroundColor: Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAllData() async {
    final txs = await TransactionRepository.instance.getAllTransactions();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '✓ Complete ledger (${txs.length} txns) exported to clipboard (CSV)!',
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
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
        backgroundColor: AppTheme.getPrimary(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canvasColor = AppTheme.getCanvas(context);

    return Scaffold(
      backgroundColor: canvasColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildTopBar(context),
              const SizedBox(height: 20),
              _buildSectionHeader('ACCOUNT & PREFERENCES'),
              const SizedBox(height: 10),
              _buildAccountPreferencesCard(context),
              const SizedBox(height: 20),
              _buildSectionHeader('AUTOMATIC DETECTION'),
              const SizedBox(height: 10),
              _buildAutomaticDetectionCard(context),
              const SizedBox(height: 20),
              _buildSectionHeader('DATA & STORAGE'),
              const SizedBox(height: 10),
              _buildDataStorageCard(context),
              const SizedBox(height: 20),
              _buildSectionHeader('PRIVACY & ABOUT'),
              const SizedBox(height: 10),
              _buildPrivacyAboutCard(context),
              const SizedBox(height: 20),
              _buildFooter(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Top Bar: "Settings" title + Notification icon + User Avatar
  Widget _buildTopBar(BuildContext context) {
    final textPrimary = AppTheme.getTextPrimary(context);
    final primary = AppTheme.getPrimary(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Settings',
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SmsDetectionScreen()),
                );
              },
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

  Widget _buildSectionHeader(String title) {
    final textSecondary = AppTheme.getTextSecondary(context);

    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: textSecondary,
      ),
    );
  }

  // 2. Account & Preferences Card
  Widget _buildAccountPreferencesCard(BuildContext context) {
    final primary = AppTheme.getPrimary(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return NeuCard(
      borderRadius: 20,
      depth: 4.0,
      blur: 8.0,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          _buildSettingsRow(
            icon: Icons.person_outline_rounded,
            iconColor: primary,
            title: 'Profile',
            subtitle: 'Personal details & security',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildSettingsRow(
            icon: Icons.currency_rupee_rounded,
            iconColor: primary,
            title: 'Currency',
            subtitle: 'Default base ledger',
            trailingWidget: Text(
              'INR (\u20B9)',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            onTap: () => _showToast('Default Currency: Indian Rupee (INR)'),
          ),
          _buildDivider(),
          _buildSettingsRow(
            icon: Icons.category_outlined,
            iconColor: primary,
            title: 'Categories',
            subtitle: '11 categories configured',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildSettingsRow(
            icon: Icons.palette_outlined,
            iconColor: primary,
            title: 'Appearance & Theme',
            subtitle: 'Neumorphic Light / Dark switcher',
            trailingWidget: Text(
              AppTheme.isDark(context) ? 'Dark' : 'Light',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // 3. Automatic Detection Card
  Widget _buildAutomaticDetectionCard(BuildContext context) {
    final textPrimary = AppTheme.getTextPrimary(context);

    return NeuCard(
      borderRadius: 20,
      depth: 4.0,
      blur: 8.0,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AutomaticDetectionScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  NeuInset(
                    borderRadius: 12,
                    padding: const EdgeInsets.all(9),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SMS Detection',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Active (Engine v2.4)',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  NeuSwitch(
                    value: _smsDetection,
                    onChanged: (val) {
                      setState(() => _smsDetection = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildDivider(),
          _buildSettingsRow(
            icon: Icons.fact_check_outlined,
            iconColor: AppTheme.getPrimary(context),
            title: 'Transaction Review',
            subtitle: 'Require confirmation before recording',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AutomaticDetectionScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // 4. Data & Storage Card
  Widget _buildDataStorageCard(BuildContext context) {
    final primary = AppTheme.getPrimary(context);

    return NeuCard(
      borderRadius: 20,
      depth: 4.0,
      blur: 8.0,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          _buildSettingsRow(
            icon: Icons.file_download_outlined,
            iconColor: primary,
            title: 'Export Data',
            subtitle: 'CSV ledger export to clipboard',
            onTap: _exportAllData,
          ),
          _buildDivider(),
          _buildSettingsRow(
            icon: Icons.file_upload_outlined,
            iconColor: primary,
            title: 'Import Data',
            subtitle: 'Restore previous backup',
            onTap: () => _showToast('Select a backup file to import ledger'),
          ),
          _buildDivider(),
          _buildSettingsRow(
            icon: Icons.delete_outline_rounded,
            iconColor: const Color(0xFFEF4444),
            title: 'Delete All Data',
            titleColor: const Color(0xFFEF4444),
            subtitle: 'Irreversible purge of local ledger',
            trailingColor: const Color(0xFFEF4444),
            onTap: _showDeleteConfirmation,
          ),
        ],
      ),
    );
  }

  // 5. Privacy & About Card
  Widget _buildPrivacyAboutCard(BuildContext context) {
    final primary = AppTheme.getPrimary(context);

    return NeuCard(
      borderRadius: 20,
      depth: 4.0,
      blur: 8.0,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          _buildSettingsRow(
            icon: Icons.shield_outlined,
            iconColor: primary,
            title: 'Privacy Information',
            subtitle: 'Local processing & zero telemetry',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AutomaticDetectionScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildSettingsRow(
            icon: Icons.info_outline_rounded,
            iconColor: primary,
            title: 'About Smart Expense',
            subtitle: 'v1.4.2 (Build 2026.09) \u2022 Soft UI',
            onTap: () => _showToast('Smart Expense v1.4.2 \u2022 Neumorphic Soft UI Engine'),
          ),
        ],
      ),
    );
  }

  // 6. Footer Notice
  Widget _buildFooter() {
    final textSecondary = AppTheme.getTextSecondary(context);

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 14,
            color: textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            'All financial data stays strictly on-device',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 66,
      endIndent: 16,
      color: AppTheme.isDark(context)
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.05),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    required String subtitle,
    Widget? trailingWidget,
    Color? trailingColor,
    required VoidCallback onTap,
  }) {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            NeuInset(
              borderRadius: 12,
              padding: const EdgeInsets.all(9),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: titleColor ?? textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingWidget != null) ...[
              trailingWidget,
              const SizedBox(width: 4),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: trailingColor ?? textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
