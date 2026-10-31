import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';
import '../widgets/auth_widgets.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  static const Color primaryBlue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hPadding = (size.width * 0.05).clamp(16.0, 24.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FD),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Bottom Decorative Waves ──────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 65,
            child: IgnorePointer(
              child: CustomPaint(
                size: Size(size.width, 65),
                painter: _BottomWavePainter(),
              ),
            ),
          ),

          // ── Single Screen Non-Scrollable Layout ──────────────
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
                return SingleChildScrollView(
                  physics: isKeyboardOpen
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Top Header Section ───────────────────────
                          _buildHeader(size),

                          const SizedBox(height: 8),

                          // ── Clean White Auth Card (No Sign Up Pill) ──
                          _buildAuthCard(context),

                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Top Section: Voxora Logo, 'Speak English with Confidence' & 3D Mira Mascot
  Widget _buildHeader(Size size) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Column: Logo, Heading & Subtitle
        Expanded(
          flex: 68,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Voxora Logo Card
              Container(
                height: 42,
                width: 42,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => const Icon(
                      Icons.graphic_eq_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Heading - Fitted to completely eliminate any horizontal overflow
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Speak English',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        height: 1.15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'with ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            height: 1.15,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds),
                              child: const Text(
                                'Confidence',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.15,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -3,
                              left: 0,
                              right: 0,
                              child: CustomPaint(
                                size: const Size(double.infinity, 4),
                                painter: _SmileUnderlinePainter(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Subtitle
              const Text(
                'Your AI tutor for daily practice, real conversations and a better you — in 90 days.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Right Column: 3D Mira Tutor with Speech Bubble
        Expanded(
          flex: 32,
          child: Container(
            alignment: Alignment.centerRight,
            height: 115,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/mira_welcome.png',
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) {
                  return Image.asset(
                    'assets/images/mira_teacher.png',
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Clean White Auth Card WITHOUT the top Sign Up pill
  Widget _buildAuthCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFEEF2F6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: controller.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Email or Mobile Number Input ─────────────────
            AuthTextField(
              controller: controller.emailController,
              hintText: 'Email or Mobile Number',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: controller.validateEmail,
            ),

            const SizedBox(height: 12),

            // ── Password Input ───────────────────────────────
            AuthTextField(
              controller: controller.passwordController,
              hintText: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              showObscureToggle: true,
              textInputAction: TextInputAction.done,
              validator: controller.validatePassword,
              onFieldSubmitted: (_) => controller.login(),
            ),

            const SizedBox(height: 10),

            // ── Forgot Password? ───────────────
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: controller.goToForgotPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Login Button with Bold Fully Visible Text ─────
            Obx(() {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: controller.isLoading.value ? null : controller.login,
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.4,
                                    height: 1.25,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // ── Don't have an account? Sign Up ───────────────
            Center(
              child: InkWell(
                onTap: controller.goToRegister,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  child: RichText(
                    text: const TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Smiling curve underline under the word 'Confidence'
class _SmileUnderlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, 2);
    path.quadraticBezierTo(size.width * 0.5, size.height + 2, size.width, 1);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bottom organic pastel wave shapes matching the reference UI
class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bluePaint = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final purplePaint = Paint()
      ..color = const Color(0xFFC084FC).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    // Bottom left blue wave
    final pathBlue = Path();
    pathBlue.moveTo(0, size.height);
    pathBlue.lineTo(0, size.height - 35);
    pathBlue.quadraticBezierTo(
      size.width * 0.2,
      size.height - 65,
      size.width * 0.45,
      size.height,
    );
    pathBlue.close();
    canvas.drawPath(pathBlue, bluePaint);

    // Bottom right purple wave
    final pathPurple = Path();
    pathPurple.moveTo(size.width, size.height);
    pathPurple.lineTo(size.width, size.height - 45);
    pathPurple.quadraticBezierTo(
      size.width * 0.75,
      size.height - 75,
      size.width * 0.48,
      size.height,
    );
    pathPurple.close();
    canvas.drawPath(pathPurple, purplePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
