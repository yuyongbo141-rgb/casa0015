import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated arc gauge that reveals the Focus Quality Score.
/// The arc sweeps from 7 o'clock to 5 o'clock (240° span).
class ScoreGauge extends StatefulWidget {
  const ScoreGauge({
    super.key,
    required this.score,
    this.size = 200,
    this.animate = true,
  });

  final double score; // 0–100
  final double size;
  final bool animate;

  @override
  State<ScoreGauge> createState() => _ScoreGaugeState();
}

class _ScoreGaugeState extends State<ScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    if (widget.animate) _ctrl.forward();
  }

  @override
  void didUpdateWidget(ScoreGauge old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) {
        final displayed = widget.score * _anim.value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _GaugePainter(
              score: displayed,
              color: AppTheme.scoreColor(displayed),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayed.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: widget.size * 0.24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.scoreColor(displayed),
                      height: 1,
                    ),
                  ),
                  Text(
                    'Focus Score',
                    style: TextStyle(
                      fontSize: widget.size * 0.075,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.score, required this.color});

  final double score;
  final Color color;

  static const double _startAngle = 150; // degrees from 3 o'clock
  static const double _sweepTotal = 240; // degrees

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;
    final strokeW = size.width * 0.06;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track
    final trackPaint = Paint()
      ..color = AppTheme.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      _deg2rad(_startAngle),
      _deg2rad(_sweepTotal),
      false,
      trackPaint,
    );

    // Filled arc
    if (score > 0) {
      final filledSweep = _sweepTotal * (score / 100);
      final paint = Paint()
        ..shader = SweepGradient(
          startAngle: _deg2rad(_startAngle),
          endAngle: _deg2rad(_startAngle + _sweepTotal),
          colors: [color.withAlpha(180), color],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        _deg2rad(_startAngle),
        _deg2rad(filledSweep),
        false,
        paint,
      );
    }
  }

  double _deg2rad(double deg) => deg * pi / 180;

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.score != score || old.color != color;
}
