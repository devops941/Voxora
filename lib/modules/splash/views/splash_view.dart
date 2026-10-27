import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:voxora/core/constants/app_constants.dart';
import 'package:voxora/modules/splash/controllers/splash_controller.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Ensure SplashController is running if registered in GetX
    if (Get.isRegistered<SplashController>()) {
      Get.find<SplashController>();
    }

    // Set translucent status bar with dark icons to match sky background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    // Progress bar animation (runs for splash duration)
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: AppConstants.splashDuration),
    )..forward();

    // Gentle floating bobbing animation for the robot
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;

          // Responsive calculations for any screen size
          final robotSize = (screenHeight * 0.28)
              .clamp(160.0, 270.0)
              .clamp(0.0, screenWidth * 0.65);
          final progressWidth = (screenWidth * 0.58).clamp(180.0, 260.0);
          final titleFontSize = (screenWidth * 0.09).clamp(28.0, 38.0);
          final subtitleFontSize = (screenWidth * 0.042).clamp(14.0, 16.5);
          final taglineFontSize = (screenWidth * 0.035).clamp(12.0, 13.5);

          return Stack(
            children: [
              // ── Beautiful Sky & Cloud Background ───────────────────────
              Positioned.fill(
                child: CustomPaint(
                  painter: _CloudsPainter(),
                ),
              ),

              // ── Responsive Content with No Overflow Guarantee ──────────
              SafeArea(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenHeight - MediaQuery.of(context).padding.vertical,
                      minWidth: screenWidth,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Spacer(flex: 3),

                          // ── Robot in Clouds with Floating Motion ──────────
                          AnimatedBuilder(
                            animation: _floatAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _floatAnimation.value),
                                child: child,
                              );
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Soft glow beneath the robot
                                Container(
                                  width: robotSize * 0.85,
                                  height: robotSize * 0.85,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF67B5FA)
                                            .withValues(alpha: 0.25),
                                        blurRadius: 36,
                                        spreadRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),

                                // Robot image
                                _RobotImage(size: robotSize),

                                // Soft mist overlay at base of robot for cloud immersion
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: (robotSize * 0.16).clamp(24.0, 38.0),
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.white.withValues(alpha: 0.0),
                                            Colors.white.withValues(alpha: 0.45),
                                            Colors.white.withValues(alpha: 0.85),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ── Brand Title ──────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'SpeakBetter',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: const Color(0xFF1B3B6F),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ── Subtitle ──────────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              '90 Days to Confident You',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2C4D75),
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ── Tagline ───────────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'AI Powered Spoken English Coach',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: taglineFontSize,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6386AD),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),

                          const Spacer(flex: 3),

                          // ── Bottom Progress & Loading ─────────────────────
                          Padding(
                            padding: const EdgeInsets.only(bottom: 40, top: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Loading...',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF5D84AC),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                AnimatedBuilder(
                                  animation: _progressController,
                                  builder: (context, _) {
                                    return _CapsuleProgressBar(
                                      progress: _progressController.value,
                                      width: progressWidth,
                                      height: 8.5,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A sleek pill / capsule progress bar with rounded ends matching the UI design
class _CapsuleProgressBar extends StatelessWidget {
  final double progress;
  final double width;
  final double height;

  const _CapsuleProgressBar({
    required this.progress,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFD4E7FA),
        borderRadius: BorderRadius.circular(height),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1E75EB),
                  Color(0xFF2575FC),
                ],
              ),
              borderRadius: BorderRadius.circular(height),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E75EB).withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Displays robo.png with fallback
class _RobotImage extends StatelessWidget {
  final double size;
  const _RobotImage({required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/robo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _FallbackRobot(size: size),
    );
  }
}

/// Graceful fallback icon if image asset is unavailable
class _FallbackRobot extends StatelessWidget {
  final double size;
  const _FallbackRobot({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF67B5FA).withValues(alpha: 0.15),
      ),
      child: Icon(
        Icons.smart_toy_rounded,
        size: size * 0.45,
        color: const Color(0xFF1B3B6F),
      ),
    );
  }
}

/// Paints the sky blue gradient and soft dreamy clouds
class _CloudsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sky base gradient
    final Rect rect = Offset.zero & size;
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF67B5FA), // Crisp sky blue at top
          Color(0xFF86C6FC),
          Color(0xFFB4DCFD),
          Color(0xFFDDF0FE),
          Color(0xFFF2F8FE), // Soft misty white-blue
          Color(0xFFE8F4FD),
        ],
        stops: [0.0, 0.22, 0.45, 0.65, 0.85, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // Helper to draw soft cumulus cloud puffs with radial gradient
    void drawPuff(Offset center, double radius, double opacity, [Color color = Colors.white]) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.7),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    // ── Upper left soft background clouds ───────────────────────────────
    drawPuff(Offset(size.width * 0.05, size.height * 0.15), size.width * 0.28, 0.55);
    drawPuff(Offset(size.width * 0.16, size.height * 0.12), size.width * 0.22, 0.45);
    drawPuff(Offset(0.0, size.height * 0.20), size.width * 0.32, 0.60);

    // ── Upper right soft background clouds ──────────────────────────────
    drawPuff(Offset(size.width * 0.95, size.height * 0.18), size.width * 0.30, 0.55);
    drawPuff(Offset(size.width * 0.82, size.height * 0.14), size.width * 0.24, 0.45);
    drawPuff(Offset(size.width * 1.02, size.height * 0.24), size.width * 0.28, 0.50);

    // ── Mid cloud bank beneath and around the robot ─────────────────────
    final midY = size.height * 0.42;
    drawPuff(Offset(size.width * 0.15, midY + 15), size.width * 0.35, 0.70);
    drawPuff(Offset(size.width * 0.38, midY + 30), size.width * 0.38, 0.85);
    drawPuff(Offset(size.width * 0.62, midY + 30), size.width * 0.38, 0.85);
    drawPuff(Offset(size.width * 0.85, midY + 15), size.width * 0.35, 0.70);
    drawPuff(Offset(size.width * 0.50, midY + 45), size.width * 0.45, 0.90);

    // ── Soft mist overlay to blend into lower screen ────────────────────
    final mistRect = Rect.fromLTWH(0, midY + 10, size.width, size.height * 0.25);
    final mistPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.60),
          Colors.white.withValues(alpha: 0.85),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(mistRect);
    canvas.drawRect(mistRect, mistPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
