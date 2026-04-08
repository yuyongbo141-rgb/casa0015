import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';

/// 2.5 s animated splash → onboarding (first run) or dashboard (returning).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _logoScale = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn);
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await _logoCtrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await _textCtrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) _navigate();
  }

  Future<void> _navigate() async {
    final settings = context.read<SettingsProvider>();
    final sessions = context.read<SessionProvider>();

    await sessions.loadHistory(demoMode: settings.demoMode);

    if (!mounted) return;
    if (!settings.hasOnboarded) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated logo
            FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: const _LogoMark(size: 110),
              ),
            ),
            const SizedBox(height: 28),
            // App name + tagline
            SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (r) =>
                          AppTheme.primaryGradient.createShader(r),
                      child: const Text(
                        'FocusShield',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Master your study environment',
                      style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Logo mark – custom painted hexagonal shield ────────────────────────────

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ShieldPainter()),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.46;

    // Shield path
    final path = Path();
    path.moveTo(cx, cy - r);
    path.cubicTo(cx + r * 0.9, cy - r * 0.6,
                 cx + r * 0.9, cy + r * 0.2,
                 cx,            cy + r);
    path.cubicTo(cx - r * 0.9, cy + r * 0.2,
                 cx - r * 0.9, cy - r * 0.6,
                 cx,            cy - r);

    // Gradient fill
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.primary, AppTheme.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, fillPaint);

    // Inner glow ring
    final glowPaint = Paint()
      ..color = Colors.white.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, glowPaint);

    // Lightning bolt icon
    final boltPaint = Paint()
      ..color = Colors.white.withAlpha(230)
      ..style = PaintingStyle.fill;
    final bolt = Path();
    final bx = cx;
    final by = cy;
    bolt.moveTo(bx - size.width * 0.08, by - size.height * 0.18);
    bolt.lineTo(bx + size.width * 0.12, by - size.height * 0.18);
    bolt.lineTo(bx - size.width * 0.02, by + size.height * 0.02);
    bolt.lineTo(bx + size.width * 0.10, by + size.height * 0.02);
    bolt.lineTo(bx - size.width * 0.12, by + size.height * 0.20);
    bolt.lineTo(bx + size.width * 0.02, by + size.height * 0.02);
    bolt.lineTo(bx - size.width * 0.08, by + size.height * 0.02);
    bolt.close();
    canvas.drawPath(bolt, boltPaint);

    // Rotating dashes ring
    final dashPaint = Paint()
      ..color = AppTheme.secondary.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi;
      final innerR = r * 1.12;
      final outerR = r * 1.22;
      canvas.drawLine(
        Offset(cx + innerR * cos(angle), cy + innerR * sin(angle)),
        Offset(cx + outerR * cos(angle), cy + outerR * sin(angle)),
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
