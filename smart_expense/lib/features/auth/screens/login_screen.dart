import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/screens/main_wrapper_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = true;
  bool _isSetupMode = false;
  int _setupStep = 0; // 0 = enter new PIN, 1 = confirm new PIN
  String _firstEnteredPin = '';
  String _currentPin = '';
  String? _savedPin;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkExistingPin();
  }

  Future<void> _checkExistingPin() async {
    try {
      final pin = await DatabaseHelper.instance.getAppPin();
      if (!mounted) return;
      setState(() {
        _savedPin = pin;
        _isSetupMode = (pin == null || pin.trim().length != 4);
        _setupStep = 0;
        _firstEnteredPin = '';
        _currentPin = '';
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSetupMode = true;
          _isLoading = false;
        });
      }
    }
  }

  void _onDigitPressed(String digit) {
    if (_currentPin.length >= 4) return;

    HapticFeedback.lightImpact();
    setState(() {
      _currentPin += digit;
      _errorMessage = null;
    });

    if (_currentPin.length == 4) {
      _processCompletePin(_currentPin);
    }
  }

  void _onBackspacePressed() {
    if (_currentPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _processCompletePin(String pin) async {
    if (_isSetupMode) {
      if (_setupStep == 0) {
        // Step 1 done -> Move to confirm step
        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        setState(() {
          _firstEnteredPin = pin;
          _currentPin = '';
          _setupStep = 1;
          _errorMessage = null;
        });
      } else {
        // Step 2: Confirm PIN
        if (pin == _firstEnteredPin) {
          HapticFeedback.mediumImpact();
          await DatabaseHelper.instance.setAppPin(pin);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '✓ 4-Digit Security PIN successfully created!',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF006C49),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainWrapperScreen()),
          );
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _errorMessage = 'PINs do not match. Please start over.';
          });
          await Future.delayed(const Duration(milliseconds: 600));
          if (!mounted) return;
          setState(() {
            _currentPin = '';
            _firstEnteredPin = '';
            _setupStep = 0;
          });
        }
      }
    } else {
      // Unlock Mode
      if (pin == _savedPin) {
        HapticFeedback.mediumImpact();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainWrapperScreen()),
        );
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = 'Incorrect PIN. Please try again.';
        });
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        setState(() {
          _currentPin = '';
        });
      }
    }
  }

  void _handleBiometricUnlock() {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.fingerprint_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Biometric match verified',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4648D4),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainWrapperScreen()),
    );
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: Color(0xFFBA1A1A), size: 24),
            SizedBox(width: 10),
            Text(
              'Reset Security PIN?',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'You can reset your 4-digit PIN. Your saved transactions, offline records, and ledger data will remain 100% safe.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13.5, height: 1.4, color: Color(0xFF464554)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Inter', color: Color(0xFF767586))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await DatabaseHelper.instance.clearAppPin();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              setState(() {
                _savedPin = null;
                _isSetupMode = true;
                _setupStep = 0;
                _firstEnteredPin = '';
                _currentPin = '';
                _errorMessage = null;
              });
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PIN reset. Please create your new 4-digit PIN.'),
                  backgroundColor: Color(0xFF4648D4),
                ),
              );
            },
            child: const Text(
              'Reset PIN',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.canvas,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              _buildBrandHeader(),
              const SizedBox(height: 32),
              _buildSecurityIcon(),
              const SizedBox(height: 16),
              _buildTitleAndSubtitle(),
              const SizedBox(height: 28),
              _buildPinDotsIndicator(),
              const SizedBox(height: 12),
              _buildErrorMessage(),
              const SizedBox(height: 24),
              _buildKeypad(),
              const SizedBox(height: 20),
              _buildBottomActions(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Top Brand & Trust Header
  Widget _buildBrandHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Color(0xFF4648D4),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Smart Expense',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'LOCAL LEDGER \u2022 OFFLINE FIRST',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Color(0xFF767586),
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              const SizedBox(width: 5),
              const Text(
                'Secure',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF006C49),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. Security Shield / Lock Icon
  Widget _buildSecurityIcon() {
    final isError = _errorMessage != null;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFDAD6) : const Color(0xFFEAEDFF),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _isSetupMode
            ? Icons.lock_outline_rounded
            : Icons.fingerprint_rounded,
        size: 34,
        color: isError ? const Color(0xFFBA1A1A) : const Color(0xFF4648D4),
      ),
    );
  }

  // 3. Title & Subtitle based on Setup vs Unlock
  Widget _buildTitleAndSubtitle() {
    String title;
    String subtitle;

    if (_isSetupMode) {
      if (_setupStep == 0) {
        title = 'Create 4-Digit PIN';
        subtitle = 'Set a 4-digit security PIN to protect your expense ledger.';
      } else {
        title = 'Confirm Your PIN';
        subtitle = 'Enter the same 4-digit PIN again to confirm.';
      }
    } else {
      title = 'Enter Security PIN';
      subtitle = 'Enter your 4-digit PIN to access your account.';
    }

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            height: 1.4,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // 4. 4 Animated PIN Dots
  Widget _buildPinDotsIndicator() {
    final isError = _errorMessage != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < _currentPin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isError
                ? const Color(0xFFBA1A1A)
                : (isFilled ? const Color(0xFF4648D4) : Colors.white),
            border: Border.all(
              color: isError
                  ? const Color(0xFFBA1A1A)
                  : (isFilled ? const Color(0xFF4648D4) : const Color(0xFFC4C5D9)),
              width: 2,
            ),
            boxShadow: isFilled && !isError
                ? [
                    BoxShadow(
                      color: const Color(0xFF4648D4).withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  // 5. Error Message Display
  Widget _buildErrorMessage() {
    if (_errorMessage == null) {
      return const SizedBox(height: 20);
    }
    return Text(
      _errorMessage!,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFFBA1A1A),
      ),
    );
  }

  // 6. Responsive Numeric Keypad
  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        const SizedBox(height: 16),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: 16),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: 16),
        _buildKeypadBottomRow(),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) => _buildKeypadButton(digit)).toList(),
    );
  }

  Widget _buildKeypadBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Left Button: Biometric in Unlock Mode, or Back in Step 1
        if (!_isSetupMode)
          _buildActionKey(
            icon: Icons.fingerprint_rounded,
            onTap: _handleBiometricUnlock,
            color: const Color(0xFF4648D4),
          )
        else if (_setupStep == 1)
          _buildActionKey(
            icon: Icons.arrow_back_rounded,
            onTap: () {
              setState(() {
                _setupStep = 0;
                _firstEnteredPin = '';
                _currentPin = '';
                _errorMessage = null;
              });
            },
            color: const Color(0xFF767586),
          )
        else
          const SizedBox(width: 72, height: 72),

        // Center Button: 0
        _buildKeypadButton('0'),

        // Right Button: Backspace
        _buildActionKey(
          icon: Icons.backspace_outlined,
          onTap: _onBackspacePressed,
          color: AppTheme.textPrimary,
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String digit) {
    return InkWell(
      onTap: () => _onDigitPressed(digit),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }

  // 7. Bottom Actions: Forgot PIN? / Remember PIN note
  Widget _buildBottomActions() {
    if (_isSetupMode) {
      return Text(
        _setupStep == 0
            ? 'Step 1 of 2: Enter 4 digits'
            : 'Step 2 of 2: Re-enter 4 digits to confirm',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4648D4),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: _showForgotPinDialog,
          child: const Text(
            'Forgot PIN?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4648D4),
            ),
          ),
        ),
      ],
    );
  }
}
