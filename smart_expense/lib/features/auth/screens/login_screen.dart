import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/neumorphic/neu_card.dart';
import '../../../core/widgets/neumorphic/neu_inset.dart';
import '../../../core/widgets/neumorphic/neu_button.dart';
import '../../home/screens/main_wrapper_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 0: Phone OTP, 1: Google Sign-In, 2: 4-Digit Security PIN
  int _selectedAuthMethod = 0;

  // Phone OTP State
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isOtpSent = false;
  String? _verificationId;
  int? _resendToken;
  bool _isLoading = false;
  String? _errorMessage;

  // Resend Timer
  int _resendCountdown = 60;
  Timer? _timer;

  // PIN Unlock State (if user has set a local PIN)
  String? _savedPin;
  String _enteredPin = '';
  bool _hasSavedPin = false;

  @override
  void initState() {
    super.initState();
    _checkSavedPin();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _nameController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _checkSavedPin() async {
    final pin = await DatabaseHelper.instance.getAppPin();
    if (mounted) {
      setState(() {
        _savedPin = pin;
        _hasSavedPin = pin != null && pin.trim().length == 4;
      });
    }
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        t.cancel();
      }
    });
  }

  // --- GOOGLE SIGN-IN ---
  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCred = await AuthService.instance.signInWithGoogle();
      if (userCred != null && mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainWrapperScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message ?? 'Google Sign-In failed. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Google Sign-In error: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- PHONE OTP: SEND OTP ---
  Future<void> _handleSendOtp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number');
      return;
    }

    final formattedPhone = rawPhone.startsWith('+') ? rawPhone : '+91$rawPhone';

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.sendPhoneOtp(
        phoneNumber: formattedPhone,
        resendToken: _resendToken,
        onCodeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isOtpSent = true;
            _isLoading = false;
          });
          _startResendTimer();
          // Focus first OTP field
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && _otpFocusNodes.isNotEmpty) {
              _otpFocusNodes[0].requestFocus();
            }
          });
        },
        onVerificationFailed: (e) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorMessage = e.message ?? 'OTP verification failed. Check phone number.';
          });
        },
        onVerificationCompleted: (credential) async {
          if (!mounted) return;
          setState(() => _isLoading = false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainWrapperScreen()),
          );
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not send SMS OTP: ${e.toString()}';
        });
      }
    }
  }

  // --- PHONE OTP: VERIFY OTP ---
  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits of the OTP');
      return;
    }

    if (_verificationId == null) {
      setState(() => _errorMessage = 'Session expired. Please resend OTP.');
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.verifyOtpAndSignIn(
        verificationId: _verificationId!,
        smsCode: otp,
        phoneNumber: '+91${_phoneController.text.trim()}',
        preferredName: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
      );

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainWrapperScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message ?? 'Invalid OTP code. Please check and re-enter.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Verification error: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- PIN UNLOCK FOR RETURNING LOCAL USERS ---
  void _onPinDigit(String digit) {
    if (_enteredPin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length == 4) {
      if (_enteredPin == _savedPin) {
        HapticFeedback.mediumImpact();
        DatabaseHelper.instance.setSetting('is_logged_in', 'true');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainWrapperScreen()),
        );
      } else {
        HapticFeedback.heavyImpact();
        setState(() => _errorMessage = 'Incorrect PIN. Please try again.');
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _enteredPin = '');
        });
      }
    }
  }

  void _onPinBackspace() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canvasColor = AppTheme.getCanvas(context);

    return Scaffold(
      backgroundColor: canvasColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      _buildHeaderBranding(),
                      const SizedBox(height: 24),

                      // Auth Mode Selector
                      _buildAuthModeSelector(),
                      const SizedBox(height: 24),

                      // Active Mode Card
                      if (_selectedAuthMethod == 0)
                        _buildPhoneOtpSection()
                      else if (_selectedAuthMethod == 1)
                        _buildGoogleSignInSection()
                      else
                        _buildPinUnlockSection(),

                      const Spacer(),

                      // Footer & Security Badge
                      _buildSecurityFooter(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 1. App Header Branding
  Widget _buildHeaderBranding() {
    final primary = AppTheme.getPrimary(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return Column(
      children: [
        NeuCard(
          borderRadius: 22,
          depth: 5.0,
          blur: 10.0,
          color: primary,
          padding: const EdgeInsets.all(16),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Smart Expense',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Smart automated expenses from SMS & UPI alerts',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  // 2. Auth Mode Segmented Selector (Phone OTP / Google / PIN)
  Widget _buildAuthModeSelector() {
    return NeuInset(
      borderRadius: 16,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildSelectorTab(
            index: 0,
            title: 'Phone OTP',
            icon: Icons.phone_android_rounded,
          ),
          _buildSelectorTab(
            index: 1,
            title: 'Google',
            icon: Icons.g_mobiledata_rounded,
          ),
          if (_hasSavedPin)
            _buildSelectorTab(
              index: 2,
              title: 'PIN',
              icon: Icons.lock_outline_rounded,
            ),
        ],
      ),
    );
  }

  Widget _buildSelectorTab({
    required int index,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedAuthMethod == index;
    final primary = AppTheme.getPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedAuthMethod = index;
            _errorMessage = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.getSurface(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? AppTheme.neuElevation(context, depth: 2.5, blur: 5.0)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? primary : textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? primary : textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Phone OTP Section
  Widget _buildPhoneOtpSection() {
    final primary = AppTheme.getPrimary(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return NeuCard(
      borderRadius: 22,
      depth: 4.5,
      blur: 9.0,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeuInset(
                borderRadius: 10,
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.phone_iphone_rounded,
                  color: primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isOtpSent ? 'Verify OTP Code' : 'Sign in with Phone',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    _isOtpSent
                        ? 'Sent to +91 ${_phoneController.text.trim()}'
                        : 'We will send a 6-digit SMS OTP',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (!_isOtpSent) ...[
            // Name field (Optional)
            NeuInset(
              borderRadius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                controller: _nameController,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Your Name (e.g. Rahul Sharma)',
                  labelStyle: TextStyle(fontSize: 13, color: textSecondary),
                  hintText: 'Enter your name',
                  hintStyle: TextStyle(fontSize: 13, color: textSecondary.withValues(alpha: 0.6)),
                  prefixIcon: Icon(Icons.person_outline, size: 20, color: primary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Phone field with +91 prefix
            NeuInset(
              borderRadius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  labelStyle: TextStyle(fontSize: 13, color: textSecondary),
                  hintText: '9876543210',
                  hintStyle: TextStyle(fontSize: 14, color: textSecondary.withValues(alpha: 0.6)),
                  counterText: '',
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    child: Text(
                      '+91',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 18),

            NeuButton(
              isPrimary: true,
              height: 48,
              borderRadius: 14,
              onPressed: _isLoading ? null : _handleSendOtp,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Get OTP',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ] else ...[
            // 6-digit OTP sunken boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return NeuInset(
                  width: 44,
                  height: 52,
                  borderRadius: 12,
                  padding: EdgeInsets.zero,
                  child: Center(
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _otpFocusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                        color: textPrimary,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && index < 5) {
                          _otpFocusNodes[index + 1].requestFocus();
                        } else if (val.isEmpty && index > 0) {
                          _otpFocusNodes[index - 1].requestFocus();
                        }
                        if (index == 5 && val.isNotEmpty) {
                          _handleVerifyOtp();
                        }
                      },
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isOtpSent = false;
                      _errorMessage = null;
                    });
                  },
                  child: Text(
                    'Change Number',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _resendCountdown == 0 ? _handleSendOtp : null,
                  child: Text(
                    _resendCountdown > 0
                        ? 'Resend in ${_resendCountdown}s'
                        : 'Resend Code',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _resendCountdown > 0
                          ? textSecondary
                          : primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            NeuButton(
              isPrimary: true,
              height: 48,
              borderRadius: 14,
              onPressed: _isLoading ? null : _handleVerifyOtp,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Verify & Continue',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  // 4. Google Sign-In Section
  Widget _buildGoogleSignInSection() {
    final primary = AppTheme.getPrimary(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return NeuCard(
      borderRadius: 22,
      depth: 4.5,
      blur: 9.0,
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          NeuInset(
            borderRadius: 28,
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.g_mobiledata_rounded,
              color: AppTheme.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Continue with Google',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Instantly sync your real profile name & email with 1-click Google authentication.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.4,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          NeuButton(
            isPrimary: false,
            height: 52,
            borderRadius: 14,
            onPressed: _isLoading ? null : _handleGoogleSignIn,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: primary,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
                        width: 22,
                        height: 22,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.g_mobiledata_rounded,
                          size: 26,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // 5. PIN Unlock Section (For returning offline users)
  Widget _buildPinUnlockSection() {
    final primary = AppTheme.getPrimary(context);
    final textPrimary = AppTheme.getTextPrimary(context);

    return NeuCard(
      borderRadius: 22,
      depth: 4.5,
      blur: 9.0,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Enter 4-Digit Security PIN',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 18),

          // 4 Animated Dots inside NeuInset depressions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFilled = index < _enteredPin.length;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: NeuInset(
                  width: 22,
                  height: 22,
                  borderRadius: 11,
                  padding: EdgeInsets.zero,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: isFilled ? 12 : 0,
                      height: isFilled ? 12 : 0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? primary : Colors.transparent,
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Numeric Keypad
          _buildNumericKeypad(),
        ],
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Column(
      children: [
        for (var row = 0; row < 3; row++) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var col = 1; col <= 3; col++)
                _buildKeypadButton('${row * 3 + col}'),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 68, height: 50),
            _buildKeypadButton('0'),
            NeuCard(
              borderRadius: 14,
              depth: 3.0,
              blur: 6.0,
              onTap: _onPinBackspace,
              child: SizedBox(
                width: 68,
                height: 50,
                child: Center(
                  child: Icon(
                    Icons.backspace_outlined,
                    size: 22,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String digit) {
    return NeuCard(
      borderRadius: 14,
      depth: 3.0,
      blur: 6.0,
      onTap: () => _onPinDigit(digit),
      child: SizedBox(
        width: 68,
        height: 50,
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
        ),
      ),
    );
  }

  // 6. Security Footer
  Widget _buildSecurityFooter() {
    final textSecondary = AppTheme.getTextSecondary(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF00B074)),
            const SizedBox(width: 6),
            Text(
              '100% Offline Ledger \u2022 Financial Privacy Guaranteed',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.isDark(context)
                    ? const Color(0xFF34D399)
                    : const Color(0xFF006C49),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            DatabaseHelper.instance.setSetting('is_logged_in', 'true');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainWrapperScreen()),
            );
          },
          child: Text(
            'Continue Offline as Guest',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textSecondary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
