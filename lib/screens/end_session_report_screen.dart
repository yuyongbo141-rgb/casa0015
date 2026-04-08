import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/score_gauge.dart';

/// Full post-session report with animated score reveal and insights.
class EndSessionReportScreen extends StatefulWidget {
  const EndSessionReportScreen({super.key});

  @override
  State<EndSessionReportScreen> createState() => _EndSessionReportScreenState();
}

class _EndSessionReportScreenState extends State<EndSessionReportScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    // Delay slide-in so the gauge animation plays first
    Future<void>.delayed(const Duration(milliseconds: 500),
        () { if (mounted) _slideCtrl.forward(); });
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _done() {
    context.read<SessionProvider>().resetSession();
    Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
  }

  String _durStr(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SessionProvider>();
    final session = sp.current;
    if (session == null || session.score == null) {
      return const Scaffold(
          backgroundColor: AppTheme.background,
          body: Center(child: CircularProgressIndicator(color: AppTheme.primary)));
    }

    final score = session.score!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Session Complete!',
                            style: AppTheme.headlineMedium),
                        Text(session.name,
                            style: AppTheme.bodyMedium),
                      ],
                    ),
                    const Spacer(),
                    TextButton(
                        onPressed: _done,
                        child: const Text('Done')),
                  ],
                ),
              ),
            ),

            // ── Score gauge ──
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: ScoreGauge(score: score.total, size: 220),
                ),
              ),
            ),

            // ── Meta row ──
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _MetaChip(
                          icon: Icons.timer_outlined,
                          label: _durStr(session.actualDuration)),
                      const SizedBox(width: 8),
                      _MetaChip(
                          icon: Icons.location_on_outlined,
                          label: session.location),
                      if (session.weatherCondition != null) ...[
                        const SizedBox(width: 8),
                        _MetaChip(
                            icon: Icons.cloud_outlined,
                            label: session.weatherCondition!),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── Score breakdown ──
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Score Breakdown',
                          style: AppTheme.headlineMedium),
                      const SizedBox(height: 14),
                      _ScoreRow(
                          label: 'Noise Environment',
                          icon: Icons.graphic_eq_rounded,
                          score: score.noiseScore),
                      const SizedBox(height: 10),
                      _ScoreRow(
                          label: 'Physical Stillness',
                          icon: Icons.vibration_rounded,
                          score: score.movementScore),
                      const SizedBox(height: 10),
                      _ScoreRow(
                          label: 'Ambient Light',
                          icon: Icons.wb_sunny_outlined,
                          score: score.lightScore),
                      const SizedBox(height: 10),
                      _ScoreRow(
                          label: 'Session Duration',
                          icon: Icons.timer_outlined,
                          score: score.durationScore),
                    ],
                  ),
                ),
              ),
            ),

            // ── Positives ──
            if (score.positives.isNotEmpty)
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnim,
                  child: _InsightSection(
                    title: 'What Helped',
                    items: score.positives,
                    color: AppTheme.success,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
              ),

            // ── Negatives ──
            if (score.negatives.isNotEmpty)
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnim,
                  child: _InsightSection(
                    title: 'What Hurt',
                    items: score.negatives,
                    color: AppTheme.error,
                    icon: Icons.cancel_outlined,
                  ),
                ),
              ),

            // ── Recommendations ──
            if (score.recommendations.isNotEmpty)
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnim,
                  child: _InsightSection(
                    title: 'Next Time',
                    items: score.recommendations,
                    color: AppTheme.secondary,
                    icon: Icons.lightbulb_outline_rounded,
                  ),
                ),
              ),

            // ── Done button ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<SessionProvider>().resetSession();
                          Navigator.pushReplacementNamed(context, '/start');
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('New Session'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _done,
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('Dashboard'),
                      ),
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500)),
        ]),
      );
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow(
      {required this.label, required this.icon, required this.score});
  final String label;
  final IconData icon;
  final double score;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.scoreColor(score);
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(label, style: AppTheme.bodyLarge),
                  const Spacer(),
                  Text(score.toStringAsFixed(0),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: color,
                          fontSize: 15)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 5,
                  backgroundColor: AppTheme.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection({
    required this.title,
    required this.items,
    required this.color,
    required this.icon,
  });
  final String title;
  final List<String> items;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.headlineMedium),
            const SizedBox(height: 10),
            ...items.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(s,
                              style: AppTheme.bodyLarge)),
                    ],
                  ),
                )),
          ],
        ),
      );
}
