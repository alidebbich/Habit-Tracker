import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import 'onboarding_screen.dart';
import '../services/miui_permission_service.dart';

// =============================================================================
// SplashScreen — shown on every cold-start while the app initialises.
// Checks whether onboarding is complete and routes accordingly.
// =============================================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Colours from the app's global theme
  static const Color _void = Color(0xFF0A0F06);
  static const Color _cream = Color(0xFFEDE5C8);

  // Animation controllers
  late final AnimationController _ringCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _startup();
  }

  Future<void> _startup() async {
    // Run minimum display time and prefs check in parallel
    final results = await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 2800)),
      SharedPreferences.getInstance()
          .then((p) => p.getBool('onboarding_done') ?? false),
    ]);
    final onboardingDone = results[1] as bool;

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) =>
            onboardingDone ? const HomeScreen() : const OnboardingScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    // Show MIUI setup dialog on Xiaomi/Redmi devices after navigation settles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        MiuiPermissionService.showIfNeeded(context);
      }
    });
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _void,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // ── Animated alarm icon ──────────────────────────────────────
              _AnimatedAlarmIcon(
                ringCtrl: _ringCtrl,
                pulseCtrl: _pulseCtrl,
                glowCtrl: _glowCtrl,
              ),

              const SizedBox(height: 48),

              // ── App name ─────────────────────────────────────────────────
              const Text(
                'Momentum',
                style: TextStyle(
                  color: _cream,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 700.ms)
                  .slideY(begin: 0.25, end: 0, curve: Curves.easeOut),

              const SizedBox(height: 10),

              // ── Tagline ──────────────────────────────────────────────────
              Text(
                'Wake up. Build habits. Own your morning.',
                style: TextStyle(
                  color: _cream.withOpacity(0.40),
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 700.ms, duration: 800.ms),

              const Spacer(flex: 2),

              // ── Bouncing dots ────────────────────────────────────────────
              const _BouncingDots()
                  .animate()
                  .fadeIn(delay: 1200.ms, duration: 600.ms),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Animated alarm icon: rotating dashed ring + pulsing glow circle
// =============================================================================

class _AnimatedAlarmIcon extends StatelessWidget {
  final AnimationController ringCtrl;
  final AnimationController pulseCtrl;
  final AnimationController glowCtrl;

  static const Color _glow = Color(0xFFB5D96B);
  static const Color _cream = Color(0xFFEDE5C8);

  const _AnimatedAlarmIcon({
    required this.ringCtrl,
    required this.pulseCtrl,
    required this.glowCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ringCtrl, pulseCtrl, glowCtrl]),
      builder: (_, __) {
        final pulse = _ease(pulseCtrl.value);
        final glow = _ease(glowCtrl.value);
        final angle = ringCtrl.value * 2 * pi;

        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ambient glow
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _glow.withOpacity(0.08 + glow * 0.18),
                      blurRadius: 50 + glow * 40,
                      spreadRadius: 2 + glow * 10,
                    ),
                  ],
                ),
              ),

              // Rotating dashed ring
              Transform.rotate(
                angle: angle,
                child: CustomPaint(
                  size: const Size(175, 175),
                  painter: _DashedRingPainter(
                    color: _glow.withOpacity(0.28 + glow * 0.18),
                    dashCount: 18,
                  ),
                ),
              ),

              // Inner glow circle
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _glow.withOpacity(0.06 + pulse * 0.08),
                  border: Border.all(
                    color: _glow.withOpacity(0.35 + pulse * 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _glow.withOpacity(0.10 + pulse * 0.15),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.alarm_rounded,
                  size: 60,
                  color: _cream.withOpacity(0.88 + pulse * 0.12),
                ),
              ),
            ],
          ),
        );
      },
    )
        .animate()
        .scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1.0, 1.0),
          duration: 900.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 500.ms);
  }

  // Ease value: smooth 0→1→0 based on controller.value
  double _ease(double v) => (sin(v * pi)).clamp(0.0, 1.0);
}

// =============================================================================
// Custom painter: dashed circular ring
// =============================================================================

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final int dashCount;

  const _DashedRingPainter({required this.color, required this.dashCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dashAngle = 0.16;
    final gapAngle = (2 * pi / dashCount) - dashAngle;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * (dashAngle + gapAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) =>
      old.color != color || old.dashCount != dashCount;
}

// =============================================================================
// Three bouncing dots loading indicator
// =============================================================================

class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  static const Color _glow = Color(0xFFB5D96B);
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Stagger each dot by 1/3 of the cycle
            final phase = (_ctrl.value - i / 3).clamp(0.0, 1.0);
            final y = -sin(phase * pi) * 7;
            final opacity = 0.3 + sin(phase * pi) * 0.7;
            return Transform.translate(
              offset: Offset(0, y),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _glow.withOpacity(opacity.clamp(0.3, 1.0)),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
