import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/neumorphic/neu_card.dart';
import '../../../core/widgets/neumorphic/neu_inset.dart';
import '../../../core/widgets/neumorphic/neu_button.dart';
import '../../../core/widgets/neumorphic/neu_icon_button.dart';
import '../../../core/widgets/neumorphic/neu_switch.dart';
import '../../auth/screens/login_screen.dart';
import '../../expenses/repositories/transaction_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _biometricUnlock = true;
  String _displayName = 'User';
  String _email = '';
  String _phone = '';
  String _authProvider = 'Local';
  String _lastBackupTime = 'Yesterday, 11:30 PM';
  int _backupCount = 3;
  int _transactionCount = 8;
  double _dbSizeMb = 0.05;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadDbStats();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await DatabaseHelper.instance.getUserProfile();
      final bio = await DatabaseHelper.instance.getSetting('biometric_unlock');
      if (mounted) {
        setState(() {
          final savedName = profile['displayName'];
          if (savedName != null && savedName.trim().isNotEmpty) {
            _displayName = savedName.trim();
          }
          _email = profile['email'] ?? '';
          _phone = profile['phone'] ?? '';
          _authProvider = profile['authProvider'] ?? 'Local';
          if (bio != null) {
            _biometricUnlock = bio == 'true';
          }
        });
      }
    } catch (_) {}
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

  void _handleLockSession() async {
    HapticFeedback.heavyImpact();
    await AuthService.instance.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Logged out. Please sign in again.',
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
                      onPressed: () async {
                        final newName = ctrl.text.trim();
                        if (newName.isNotEmpty) {
                          setState(() => _displayName = newName);
                          await DatabaseHelper.instance.setSetting('display_name', newName);
                        }
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
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

  void _showChangePinBottomSheet() {
    final newPinCtrl = TextEditingController();
    final confirmPinCtrl = TextEditingController();
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                  const Row(
                    children: [
                      Icon(Icons.pin_outlined, color: Color(0xFF4648D4), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Change Security PIN',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter a new 4-digit PIN to secure your expense ledger.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: newPinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New 4-Digit PIN',
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: confirmPinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm 4-Digit PIN',
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorText!,
                      style: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
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
                          child: const Text('Cancel'),
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
                          onPressed: () async {
                            final p1 = newPinCtrl.text.trim();
                            final p2 = confirmPinCtrl.text.trim();
                            if (p1.length != 4) {
                              setModalState(() => errorText = 'PIN must be exactly 4 digits.');
                              return;
                            }
                            if (p1 != p2) {
                              setModalState(() => errorText = 'PINs do not match.');
                              return;
                            }
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(ctx);
                            await DatabaseHelper.instance.setAppPin(p1);
                            if (!mounted) return;
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text('✓ Security PIN updated successfully!'),
                                backgroundColor: const Color(0xFF006C49),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          child: const Text('Save PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
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
              const SizedBox(height: 16),
              _buildHeroProfileCard(),
              const SizedBox(height: 20),
              _buildThemeModeSection(),
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
    final textPrimary = AppTheme.getTextPrimary(context);
    final primary = AppTheme.getPrimary(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        NeuIconButton(
          icon: Icons.arrow_back_rounded,
          size: 40,
          iconSize: 20,
          onTap: () => Navigator.pop(context),
        ),
        Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        NeuCard(
          isCircle: true,
          depth: 3.0,
          blur: 6.0,
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.person,
            color: primary,
            size: 20,
          ),
        ),
      ],
    );
  }

  // 2. Hero Profile Card
  Widget _buildHeroProfileCard() {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final primary = AppTheme.getPrimary(context);
    final secondary = AppTheme.getSecondary(context);

    return NeuCard(
      borderRadius: 22,
      depth: 4.5,
      blur: 9.0,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          // Avatar with Edit Button Overlay
          Stack(
            children: [
              NeuInset(
                isCircle: true,
                padding: const EdgeInsets.all(4),
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'HS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
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
                      color: primary,
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
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Local Ledger Member since Aug 2024',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          // Offline First Account Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Offline First Account',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2b. Appearance & Theme Mode Section
  Widget _buildThemeModeSection() {
    final textSecondary = AppTheme.getTextSecondary(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'APPEARANCE & THEME',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        NeuCard(
          borderRadius: 18,
          depth: 4.0,
          blur: 8.0,
          padding: const EdgeInsets.all(12),
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeNotifier.instance,
            builder: (context, currentMode, _) {
              return Row(
                children: [
                  _buildThemeOption(
                    title: 'Light Soft',
                    icon: Icons.light_mode_rounded,
                    isSelected: currentMode == ThemeMode.light,
                    onTap: () => ThemeNotifier.instance.setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(width: 8),
                  _buildThemeOption(
                    title: 'Dark Soft',
                    icon: Icons.dark_mode_rounded,
                    isSelected: currentMode == ThemeMode.dark,
                    onTap: () => ThemeNotifier.instance.setThemeMode(ThemeMode.dark),
                  ),
                  const SizedBox(width: 8),
                  _buildThemeOption(
                    title: 'System',
                    icon: Icons.brightness_auto_rounded,
                    isSelected: currentMode == ThemeMode.system,
                    onTap: () => ThemeNotifier.instance.setThemeMode(ThemeMode.system),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primary = AppTheme.getPrimary(context);
    final textMuted = AppTheme.getTextMuted(context);

    if (isSelected) {
      return Expanded(
        child: NeuInset(
          borderRadius: 14,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 22, color: primary),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 22, color: textMuted),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
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
        NeuCard(
          borderRadius: 18,
          depth: 3.5,
          blur: 7.0,
          padding: EdgeInsets.zero,
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
                        children: [
                          const Text(
                            'Phone (SMS Sync)',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF767586),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _phone.isNotEmpty ? _phone : 'Not Linked',
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
                        children: [
                          const Text(
                            'Email Address',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF767586),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _email.isNotEmpty ? _email : 'Not Linked',
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
              const Divider(height: 1, indent: 66, endIndent: 14, color: Color(0xFFF1F5F9)),
              // Auth Provider Row
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
                        Icons.security_rounded,
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
                            'Auth Method',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF767586),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _authProvider.isNotEmpty ? _authProvider : 'Offline Local',
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
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
        NeuCard(
          borderRadius: 18,
          depth: 3.5,
          blur: 7.0,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Quick PIN Row
              InkWell(
                onTap: _showChangePinBottomSheet,
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
                    NeuSwitch(
                      value: _biometricUnlock,
                      onChanged: (val) {
                        setState(() => _biometricUnlock = val);
                        DatabaseHelper.instance.setSetting('biometric_unlock', val ? 'true' : 'false');
                      },
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
  // 5. Section: LOCAL STORAGE & LEDGER
  Widget _buildLocalStorageAndLedgerSection() {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final primary = AppTheme.getPrimary(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LOCAL STORAGE & LEDGER',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        NeuCard(
          borderRadius: 18,
          depth: 3.5,
          blur: 7.0,
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              // 3 Metric Cards Row
              Row(
                children: [
                  Expanded(
                    child: NeuInset(
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      child: Column(
                        children: [
                          Text(
                            'Transactions',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_transactionCount',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NeuInset(
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      child: Column(
                        children: [
                          Text(
                            'DB Size',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_dbSizeMb.toStringAsFixed(2)} MB',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NeuInset(
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      child: Column(
                        children: [
                          Text(
                            'Backups',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_backupCount Saved',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: AppTheme.isDark(context) ? const Color(0xFF282D3D) : const Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              // Last Local Backup & Create Backup CTA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Local Backup',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _lastBackupTime,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  NeuButton(
                    isPrimary: false,
                    height: 38,
                    borderRadius: 10,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    onPressed: _handleCreateBackup,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 16,
                          color: primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Create Backup',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ],
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
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final primary = AppTheme.getPrimary(context);

    return NeuCard(
      borderRadius: 16,
      depth: 3.5,
      blur: 7.0,
      padding: const EdgeInsets.all(14.0),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Linked to current device: Samsung Galaxy S23 FE'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      child: Row(
        children: [
          NeuInset(
            borderRadius: 10,
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.devices_outlined,
              color: primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Switch Device / Profile',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Linked to Pixel-7-Loc892',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  // 7. Lock Current Session Button
  Widget _buildLockCurrentSessionButton() {
    final error = AppTheme.getError(context);

    return NeuButton(
      isPrimary: false,
      height: 50,
      borderRadius: 14,
      onPressed: _handleLockSession,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: error,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Lock Current Session',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: error,
            ),
          ),
        ],
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
