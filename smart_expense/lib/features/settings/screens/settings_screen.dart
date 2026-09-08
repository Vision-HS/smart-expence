import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../categories/screens/categories_screen.dart';
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFBA1A1A)),
            SizedBox(width: 8),
            Text(
              'Delete All Data?',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'This action will permanently purge all transactions, budgets, categories, and account information from this device. This cannot be undone.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13.5, height: 1.4, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Data purge canceled (demo mode safeguard)'),
                  backgroundColor: AppTheme.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Settings',
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppTheme.textSecondary,
      ),
    );
  }

  // 2. Account & Preferences Card
  Widget _buildAccountPreferencesCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildSettingsRow(
            icon: Icons.person_outline_rounded,
            iconColor: AppTheme.primary,
            iconBg: const Color(0xFFEEF2FF),
            title: 'Profile',
            subtitle: 'Hiren \u2022 hs@email.com',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
          _buildSettingsRow(
            icon: Icons.currency_rupee_rounded,
            iconColor: AppTheme.primary,
            iconBg: const Color(0xFFEEF2FF),
            title: 'Currency',
            subtitle: 'Default base ledger',
            trailingWidget: const Text(
              'INR (\u20B9)',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            onTap: () => _showToast('Default Currency: Indian Rupee (INR)'),
          ),
          const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
          _buildSettingsRow(
            icon: Icons.category_outlined,
            iconColor: AppTheme.primary,
            iconBg: const Color(0xFFEEF2FF),
            title: 'Categories',
            subtitle: '11 categories configured',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
            },
          ),
          const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
          _buildSettingsRow(
            icon: Icons.light_mode_outlined,
            iconColor: AppTheme.primary,
            iconBg: const Color(0xFFEEF2FF),
            title: 'Appearance',
            subtitle: 'Theme & visual system',
            trailingWidget: const Text(
              'Light mode',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            onTap: () => _showToast('Appearance: Light Mode (Modern Fintech Engine)'),
          ),
        ],
      ),
    );
  }

  // 3. Automatic Detection Card
  Widget _buildAutomaticDetectionCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF006C49),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SMS Detection',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
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
                              color: Color(0xFF006C49),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Active (Engine v2.4)',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF006C49),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: _smsDetection,
                    onChanged: (val) {
                      setState(() => _smsDetection = val);
                    },
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppTheme.primary,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFD2D9F4),
                    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
          _buildSettingsRow(
            icon: Icons.fact_check_outlined,
            iconColor: AppTheme.primary,
            iconBg: const Color(0xFFEEF2FF),
            title: 'Transaction Review',
            subtitle: 'Require confirmation',
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildSettingsRow(
            icon: Icons.file_download_outlined,
            iconColor: AppTheme.primary,
            iconBg: const Color(0xFFEEF2FF),
            title: 'Export Data',
            subtitle: 'CSV, Excel, or JSON export',
            onTap: () => _showToast('Exporting ledger data (CSV/Excel/JSON)...'),
          ),
          const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
          _buildSettingsRow(
            icon: Icons.file_upload_outlined,
            iconColor: AppTheme.primary,
            iconBg: const Color(0xFFEEF2FF),
            title: 'Import Data',
            subtitle: 'Restore previous backup',
            onTap: () => _showToast('Select a backup file to import ledger'),
          ),
          const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
          _buildSettingsRow(
            icon: Icons.delete_outline_rounded,
            iconColor: const Color(0xFFBA1A1A),
            iconBg: const Color(0xFFFEE2E2),
            title: 'Delete All Data',
            titleColor: const Color(0xFFBA1A1A),
            subtitle: 'Irreversible purge of local ledger',
            trailingColor: const Color(0xFFBA1A1A),
            onTap: _showDeleteConfirmation,
          ),
        ],
      ),
    );
  }

  // 5. Privacy & About Card
  Widget _buildPrivacyAboutCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildSettingsRow(
            icon: Icons.shield_outlined,
            iconColor: AppTheme.primary,
            iconBg: const Color(0xFFEEF2FF),
            title: 'Privacy Information',
            subtitle: 'Local processing & zero telemetry',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AutomaticDetectionScreen()),
              );
            },
          ),
          const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
          _buildSettingsRow(
            icon: Icons.info_outline_rounded,
            iconColor: AppTheme.primary,
            iconBg: const Color(0xFFEEF2FF),
            title: 'About Smart Expense',
            subtitle: 'v1.4.2 (Build 2026.09)',
            onTap: () => _showToast('Smart Expense v1.4.2 â€¢ Modern Fintech Engine'),
          ),
        ],
      ),
    );
  }

  // 6. Footer Notice
  Widget _buildFooter() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.lock_outline_rounded,
            size: 14,
            color: Color(0xFF464554),
          ),
          SizedBox(width: 6),
          Text(
            'All financial data stays strictly on-device',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF464554),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    Color? titleColor,
    required String subtitle,
    Widget? trailingWidget,
    Color? trailingColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? AppTheme.textPrimary,
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
            if (trailingWidget != null) ...[
              trailingWidget,
              const SizedBox(width: 4),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: trailingColor ?? AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
