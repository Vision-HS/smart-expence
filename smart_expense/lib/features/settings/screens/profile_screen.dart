import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/screens/login_screen.dart';
import '../../expenses/repositories/transaction_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _biometricUnlock = true;
  String _displayName = 'Hiren';
  String _lastBackupTime = 'Yesterday, 11:30 PM';
  int _backupCount = 3;
  int _transactionCount = 8;
  double _dbSizeMb = 0.05;

  @override
  void initState() {
    super.initState();
    _loadDbStats();
  }

  Future<void> _loadDbStats() async {
    try {
      final stats = await TransactionRepository.instance.getDatabaseStats();
      if (mounted) {
        setState(() {
          _transactionCount = stats['count'] as int;
          _dbSizeMb = stats['dbSizeMb'] as double;
        });
      }
    } catch (_) {}
  }

  void _handleCreateBackup() {
    HapticFeedback.lightImpact();
    setState(() {
      _lastBackupTime = 'Just now';
      _backupCount += 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Encrypted local backup created successfully',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF006C49),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleLockSession() {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Session locked. PIN or Biometric required.',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF464554),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _editDisplayName() {
    final ctrl = TextEditingController(text: _displayName);
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
                'Edit Display Name',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
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
                        if (ctrl.text.trim().isNotEmpty) {
                          setState(() => _displayName = ctrl.text.trim());
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildTopBar(context),
              const SizedBox(height: 16),
              _buildHeroProfileCard(),
              const SizedBox(height: 24),
              _buildPersonalDetailsSection(),
              const SizedBox(height: 24),
              _buildSecurityAndAccessSection(),
              const SizedBox(height: 24),
              _buildLocalStorageAndLedgerSection(),
              const SizedBox(height: 16),
              _buildSwitchDeviceSection(),
              const SizedBox(height: 20),
              _buildLockCurrentSessionButton(),
              const SizedBox(height: 24),
              _buildFooter(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Top Bar: Back arrow + "Profile" + user avatar icon
  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppTheme.textPrimary,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        const Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
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
    );
  }

  // 2. Hero Profile Card
  Widget _buildHeroProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Avatar with Edit Button Overlay
          Stack(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0E3FD),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'HS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4648D4),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _editDisplayName,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4648D4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _displayName,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Local Ledger Member since Aug 2024',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF767586),
            ),
          ),
          const SizedBox(height: 10),
          // Offline First Account Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF006C49),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Offline First Account',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF006C49),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Section: PERSONAL DETAILS
  Widget _buildPersonalDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PERSONAL DETAILS',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Color(0xFF767586),
          ),
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
              // Phone (SMS Sync) Row
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAEDFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.smartphone_rounded,
                        color: Color(0xFF4648D4),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Phone (SMS Sync)',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF767586),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '+91 98765 24012',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Primary',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF006C49),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 66, endIndent: 14, color: Color(0xFFF1F5F9)),
              // Email Address Row
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAEDFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.alternate_email_rounded,
                        color: Color(0xFF4648D4),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Email Address',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF767586),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'hiren \u2022 hs@email.com',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.verified_user_outlined,
                      color: Color(0xFF006C49),
                      size: 20,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 66, endIndent: 14, color: Color(0xFFF1F5F9)),
              // Display Name Row
              InkWell(
                onTap: _editDisplayName,
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAEDFF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.badge_outlined,
                          color: Color(0xFF4648D4),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Display Name',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF767586),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _displayName,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFF767586),
                        size: 18,
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

  // 4. Section: SECURITY & ACCESS
  Widget _buildSecurityAndAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SECURITY & ACCESS',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Color(0xFF767586),
          ),
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
              // Quick PIN Row
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Quick PIN setup is active (4-Digits)'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF4648D4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAEDFF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.pin_outlined,
                          color: Color(0xFF4648D4),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Quick PIN',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '\u2022\u2022\u2022\u2022 (4-Digit Active)',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF767586),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF767586),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, indent: 66, endIndent: 14, color: Color(0xFFF1F5F9)),
              // Biometric Unlock Row
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAEDFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        color: Color(0xFF4648D4),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Biometric Unlock',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Fingerprint / Face ID',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF767586),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 0.9,
                      child: Switch(
                        value: _biometricUnlock,
                        onChanged: (val) {
                          setState(() => _biometricUnlock = val);
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
              const Divider(height: 1, indent: 66, endIndent: 14, color: Color(0xFFF1F5F9)),
              // Auto-Lock Delay Row
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Auto-lock configured: Immediately on exit'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF4648D4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAEDFF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.timer_outlined,
                          color: Color(0xFF4648D4),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Auto-Lock Delay',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Immediately on exit',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF767586),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF767586),
                        size: 20,
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

  // 5. Section: LOCAL STORAGE & LEDGER
  Widget _buildLocalStorageAndLedgerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LOCAL STORAGE & LEDGER',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Color(0xFF767586),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              // 3 Metric Cards Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Transactions',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF767586),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_transactionCount',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'DB Size',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF767586),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_dbSizeMb.toStringAsFixed(2)} MB',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Backups',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF767586),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_backupCount Saved',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              // Last Local Backup & Create Backup CTA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Local Backup',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF767586),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _lastBackupTime,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _handleCreateBackup,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAEDFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 16,
                            color: Color(0xFF4648D4),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Create Backup',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4648D4),
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
        ),
      ],
    );
  }

  // 6. Section: Switch Device / Profile
  Widget _buildSwitchDeviceSection() {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Linked to current device: Samsung Galaxy S23 FE'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF4648D4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEAEDFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.devices_outlined,
                color: Color(0xFF4648D4),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Switch Device / Profile',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Linked to Pixel-7-Loc892',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF767586),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF767586),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // 7. Lock Current Session Button
  Widget _buildLockCurrentSessionButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFBFBFE),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _handleLockSession,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFFB61722),
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Lock Current Session',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB61722),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 8. Footer Info & Privacy Tag
  Widget _buildFooter() {
    return Column(
      children: [
        const Center(
          child: Text(
            'Smart Expense v1.4.2 \u2022 Device ID: Pixel-7-Loc892',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF767586),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.shield_outlined,
              size: 13,
              color: Color(0xFF006C49),
            ),
            SizedBox(width: 5),
            Text(
              'Zero cloud access \u2022 SMS processed strictly on device',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF006C49),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
