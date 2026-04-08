import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/sensor_card.dart';
import '../widgets/focus_chart.dart';
import '../services/scoring_engine.dart';

/// Full-screen live focus timer with real-time sensor feed.
class LiveSessionScreen extends StatefulWidget {
  const LiveSessionScreen({super.key});

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen>
    with TickerProviderStateMixin {
  late Timer _clockTimer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  final _scorer = const ScoringEngine();

  @override
  void initState() {
    super.initState();

    // Clock ticker – updates the elapsed display every second
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // Pulsing ring on the timer
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _endSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('End Session?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
            'Your score will be calculated and saved.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Going'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<SessionProvider>().endSession();
      if (mounted) Navigator.pushReplacementNamed(context, '/report');
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SessionProvider>();
    final session = sp.current;
    if (session == null) {
      return const Scaffold(
          backgroundColor: AppTheme.background,
          body: Center(child: CircularProgressIndicator(color: AppTheme.primary)));
    }

    final elapsed   = DateTime.now().difference(session.startTime);
    final goal      = Duration(minutes: session.goalMinutes);
    final progress  = (elapsed.inSeconds / goal.inSeconds).clamp(0.0, 1.0);
    final readings  = sp.liveReadings;
    final latest    = sp.latestReading;
    final isPaused  = sp.sessionState == SessionState.paused;

    // Running score estimate
    double runScore = 50;
    if (readings.isNotEmpty) {
      runScore = _scorer
          .calculate(readings: readings, sessionDuration: elapsed)
          .total;
    }

    double lightScore = 50, noiseScore = 50, movScore = 50;
    if (latest != null) {
      final s = _scorer.calculate(
          readings: [latest], sessionDuration: elapsed);
      lightScore = s.lightScore;
      noiseScore = s.noiseScore;
      movScore   = s.movementScore;
    }

    return PopScope(
      canPop: false, // prevent accidental back-gesture during session
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.name,
                            style: AppTheme.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Row(children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppTheme.textSecondary),
                          const SizedBox(width: 3),
                          Text(session.location,
                              style: AppTheme.bodyMedium),
                        ]),
                      ],
                    ),
                    const Spacer(),
                    // Live score pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.scoreColor(runScore).withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.scoreColor(runScore).withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 7, height: 7,
                            decoration: BoxDecoration(
                              color: isPaused
                                  ? AppTheme.warning
                                  : AppTheme.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            runScore.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.scoreColor(runScore),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Timer ──
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: isPaused ? 1.0 : _pulseAnim.value,
                          child: child,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 8,
                                backgroundColor: AppTheme.cardBorder,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.scoreColor(runScore)),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatDuration(elapsed),
                                  style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                                Text(
                                  'of ${session.goalMinutes} min',
                                  style: AppTheme.bodyMedium,
                                ),
                                if (isPaused)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text('PAUSED',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.warning,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.5)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Mini noise chart
                      if (readings.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: LiveSensorChart(
                            readings: readings,
                            height: 60,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Sensor cards ──
              if (latest != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: SensorCard(
                          icon: Icons.wb_sunny_outlined,
                          label: 'Light',
                          value: latest.lightLux.toStringAsFixed(0),
                          unit: 'lux',
                          score: lightScore,
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SensorCard(
                          icon: Icons.graphic_eq_rounded,
                          label: 'Noise',
                          value: latest.noiseDb.toStringAsFixed(1),
                          unit: 'dB',
                          score: noiseScore,
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SensorCard(
                          icon: Icons.vibration_rounded,
                          label: 'Motion',
                          value: latest.movementMagnitude.toStringAsFixed(2),
                          unit: 'm/s²',
                          score: movScore,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Controls ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Row(
                  children: [
                    // Pause / Resume
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (isPaused) {
                            sp.resumeSession();
                          } else {
                            sp.pauseSession();
                          }
                        },
                        icon: Icon(isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded),
                        label: Text(isPaused ? 'Resume' : 'Pause'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // End
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _endSession,
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('End Session'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error.withAlpha(200),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
