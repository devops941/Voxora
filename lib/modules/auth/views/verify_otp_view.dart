import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:voxora/core/routes/app_routes.dart';
import 'package:voxora/core/theme/app_colors.dart';
import 'package:voxora/core/theme/app_text_styles.dart';
import 'package:voxora/data/repositories/auth_repository.dart';
import '../widgets/auth_widgets.dart';

class VerifyOtpView extends StatefulWidget {
  const VerifyOtpView({super.key});

  @override
  State<VerifyOtpView> createState() => _VerifyOtpViewState();
}

class _VerifyOtpViewState extends State<VerifyOtpView> {
  late final String email;
  final List<TextEditingController> _digitControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );

  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 45;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    email = (args is Map && args['email'] != null)
        ? args['email'].toString()
        : '';
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 45);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        if (mounted) setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentOtp {
    return _digitControllers.map((c) => c.text.trim()).join();
  }

  Future<void> _verifyOtp() async {
    final otp = _currentOtp;
    if (otp.length < 6) {
      Get.snackbar(
        'Incomplete Code',
        'Please enter all 6 digits of the verification code.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (Get.isRegistered<AuthRepository>()) {
        await Get.find<AuthRepository>().verifyOtp(email, otp);
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      Get.snackbar(
        'Code Verified! 🎉',
        'Please enter your new password.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF16A34A),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );

      // Navigate to Reset Password Screen with email & verified OTP
      Get.toNamed(
        AppRoutes.resetPassword,
        arguments: {'email': email, 'otp': otp},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      final msg = e.toString().replaceAll('Exception:', '').trim();
      Get.snackbar(
        'Verification Failed',
        msg.isNotEmpty ? msg : 'Incorrect verification code. Please check and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() => _isResending = true);
    try {
      if (Get.isRegistered<AuthRepository>()) {
        await Get.find<AuthRepository>().forgotPassword(email);
      }
      if (!mounted) return;
      setState(() => _isResending = false);

      // Clear current boxes and focus the first one
      for (final c in _digitControllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();

      _startCountdown();

      Get.snackbar(
        'New Code Sent! 📩',
        'A fresh 6-digit OTP has been dispatched to $email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF16A34A),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResending = false);
      Get.snackbar(
        'Resend Notice',
        'Failed to resend code. Please try again in a few moments.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // User pasted full OTP
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (int i = 0; i < 6; i++) {
        if (i < digits.length) {
          _digitControllers[i].text = digits[i];
        }
      }
      if (digits.length >= 6) {
        _focusNodes[5].unfocus();
        _verifyOtp();
      } else {
        _focusNodes[digits.length.clamp(0, 5)].requestFocus();
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOtp();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hPadding = (size.width * 0.065).clamp(18.0, 32.0);
    final iconSize = (size.width * 0.18).clamp(64.0, 84.0);
    final titleFontSize = (size.width * 0.075).clamp(24.0, 30.0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 12),
          child: AuthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: (size.height * 0.02).clamp(8.0, 24.0)),

                // Top Icon
                Center(
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      Icons.mark_email_read_rounded,
                      size: iconSize * 0.52,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),

                SizedBox(height: (size.height * 0.035).clamp(20.0, 32.0)),

                // Title
                Text(
                  'Verify Code',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      height: 1.5,
                      fontSize: 14.5,
                    ),
                    children: [
                      const TextSpan(text: 'Enter the 6-digit verification code sent to\n'),
                      TextSpan(
                        text: email.isNotEmpty ? email : 'your registered email',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: (size.height * 0.035).clamp(24.0, 36.0)),

                // 6-Digit OTP Box Grid with Responsive Sizing
                Row(
                  children: List.generate(
                    6,
                    (i) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _buildOtpBox(i, isDark),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: (size.height * 0.035).clamp(20.0, 32.0)),

                // Verify Button
                AuthPrimaryButton(
                  label: 'Verify & Continue',
                  onPressed: _verifyOtp,
                  isLoading: _isLoading,
                ),

                SizedBox(height: (size.height * 0.025).clamp(16.0, 24.0)),

                // Resend Timer / Action
                Center(
                  child: _resendCountdown > 0
                      ? Text(
                          'Resend code in ${_resendCountdown}s',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          ),
                        )
                      : TextButton.icon(
                          onPressed: _isResending ? null : _resendCode,
                          icon: _isResending
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text(
                            'Resend Code',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 8),

                // Change Email Link
                Center(
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Wrong email? Change',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index, bool isDark) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _digitControllers[index].text.isNotEmpty
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          width: _digitControllers[index].text.isNotEmpty ? 2 : 1.2,
        ),
        boxShadow: _digitControllers[index].text.isNotEmpty
            ? [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.backspace &&
                _digitControllers[index].text.isEmpty &&
                index > 0) {
              _focusNodes[index - 1].requestFocus();
              _digitControllers[index - 1].clear();
            }
          },
          child: TextField(
            controller: _digitControllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6), // allows pasting 6 digits
            ],
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (val) => _onDigitChanged(index, val),
          ),
        ),
      ),
    );
  }
}
