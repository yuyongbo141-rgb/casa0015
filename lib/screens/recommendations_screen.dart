import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';

/// Data-driven recommendations derived from the user's session history.
class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<SessionProvider>().history;
    final scored  = history.where((s) => s.score != null).toList();
    final total   = scored.length;

    // ── Compute insight data ──────────────────────────────────────────────

    // Best location
    final Map<String, List<double>> byLoc = {};
    for (final s in scored) {
      byLoc.putIfAbsent(s.location, () => []).add(s.score!.total);
    }
    String? bestLoc;
    double bestLocScore = 0;
    byLoc.forEach((loc, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg > bestLocScore) { bestLocScore = avg; bestLoc = loc; }
    });

    // Best time of day
    final Map<String, List<double>> byTime = {
      'Morning': [], 'Afternoon': [], 'Evening': [], 'Night': [],
    };
    for (final s in scored) {
      final h = s.startTime.hour;
      if (h >= 6 && h < 12) {
        byTime['Morning']!.add(s.score!.total);
      } else if (h >= 12 && h < 17) {
        byTime['Afternoon']!.add(s.score!.total);
      } else if (h >= 17 && h < 22) {
        byTime['Evening']!.add(s.score!.total);
      } else {
        byTime['Night']!.add(s.score!.total);
      }
    }
    String? bestTime;
    double bestTimeScore = 0;
    byTime.forEach((t, scores) {
      if (scores.isEmpty) return;
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg > bestTimeScore) { bestTimeScore = avg; bestTime = t; }
    });

    // Noise avoidance
    final noisy = scored.where((s) =>
        s.avgNoiseDb != null && s.avgNoiseDb! > 55 && s.score!.total < 60).length;
    final noisyPct = total > 0 ? noisy / total * 100 : 0.0;

    // Movement disruption
    final moving = scored.where((s) =>
        s.avgMovement != null && s.avgMovement! > 1.0 && s.score!.total < 65).length;

    // Streak
    final streak = _calculateStreak(history);

    // Overall avg
    final avgScore = total == 0
        ? null
        : scored.map((s) => s.score!.total).reduce((a, b) => a + b) / total;

    final tips = _buildTips(
      bestLoc: bestLoc,
      bestLocScore: bestLocScore,
      bestTime: bestTime,
      bestTimeScore: bestTimeScore,
      noisyPct: noisyPct,
      movingCount: moving,
      avgScore: avgScore,
      total: total,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recommendations', style: AppTheme.displayLarge),
                    const SizedBox(height: 4),
                    Text(
                      total > 0
                          ? 'Based on your $total sessions'
                          : 'Complete sessions to unlock insights',
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            // ── Streak + avg row ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatBubble(
                        label: 'Day Streak',
                        value: '$streak',
                        icon: Icons.local_fire_department_rounded,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBubble(
                        label: 'Avg Score',
                        value: avgScore?.toStringAsFixed(0) ?? '—',
                        icon: Icons.stars_rounded,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBubble(
                        label: 'Sessions',
                        value: '$total',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Tips ──
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 10),
                child: Text('Your Personal Tips', style: AppTheme.headlineMedium),
              ),
            ),

            if (total == 0)
              const SliverFillRemaining(child: _EmptyRec())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _TipCard(tip: tips[i]),
                  ),
                  childCount: tips.length,
                ),
              ),

            // ── General tips ──
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Text('Study Science', style: AppTheme.headlineMedium),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _ScienceTile(tile: _scienceTips[i]),
                ),
                childCount: _scienceTips.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  int _calculateStreak(List sessions) {
    if (sessions.isEmpty) return 0;
    final now = DateTime.now();
    int streak = 0;
    for (int d = 0; d < 365; d++) {
      final day = DateTime(now.year, now.month, now.day - d);
      final hasSession = sessions.any((s) {
        final sd = DateTime(
            s.startTime.year, s.startTime.month, s.startTime.day);
        return sd == day;
      });
      if (hasSession) {
        streak++;
      } else if (d > 0) {
        break;
      }
    }
    return streak;
  }

  List<_Tip> _buildTips({
    required String? bestLoc,
    required double bestLocScore,
    required String? bestTime,
    required double bestTimeScore,
    required double noisyPct,
    required int movingCount,
    required double? avgScore,
    required int total,
  }) {
    final tips = <_Tip>[];

    if (bestLoc != null) {
      tips.add(_Tip(
        icon: Icons.location_on_rounded,
        color: AppTheme.success,
        title: 'Best spot: $bestLoc',
        body: 'Your average score there is ${bestLocScore.toStringAsFixed(0)}. '
            'Prioritise this location when you need deep focus.',
      ));
    }

    if (bestTime != null) {
      tips.add(_Tip(
        icon: Icons.schedule_rounded,
        color: AppTheme.secondary,
        title: '$bestTime sessions perform best',
        body: 'You score an average of ${bestTimeScore.toStringAsFixed(0)} '
            'during the $bestTime. Schedule demanding tasks then.',
      ));
    }

    if (noisyPct > 30) {
      tips.add(_Tip(
        icon: Icons.hearing_disabled_rounded,
        color: AppTheme.warning,
        title: 'Noise is your main enemy',
        body: '${noisyPct.toStringAsFixed(0)} % of sessions had high noise '
            'and a poor score. Try noise-cancelling headphones.',
      ));
    }

    if (movingCount > 2) {
      tips.add(_Tip(
        icon: Icons.phone_android_rounded,
        color: AppTheme.error,
        title: 'Phone movement detected',
        body: '$movingCount sessions had frequent motion spikes. '
            'Put your phone face-down and enable Do Not Disturb.',
      ));
    }

    if (avgScore != null && avgScore >= 75) {
      tips.add(_Tip(
        icon: Icons.emoji_events_rounded,
        color: AppTheme.accent,
        title: 'You\'re performing well!',
        body: 'Your average of ${avgScore.toStringAsFixed(0)} puts you in '
            'the top tier. Maintain these study habits.',
      ));
    }

    if (tips.isEmpty) {
      tips.add(_Tip(
        icon: Icons.lightbulb_rounded,
        color: AppTheme.primary,
        title: 'Keep exploring',
        body: 'Try sessions in different locations and times '
            'to build a richer insight profile.',
      ));
    }

    return tips;
  }

  static const _scienceTips = [
    _SciTile(
      icon: '🧠',
      title: 'Spaced repetition beats cramming',
      body: 'Reviewing material at increasing intervals is 2× more effective than marathon study.',
    ),
    _SciTile(
      icon: '💧',
      title: 'Stay hydrated',
      body: 'Even mild dehydration (1–2 %) measurably impairs attention and working memory.',
    ),
    _SciTile(
      icon: '🌙',
      title: 'Sleep consolidates learning',
      body: 'The hippocampus replays memories during slow-wave sleep — 8 hours beats a late-night cram.',
    ),
    _SciTile(
      icon: '🏃',
      title: 'Exercise boosts BDNF',
      body: 'A 20-minute walk before studying raises brain-derived neurotrophic factor, accelerating recall.',
    ),
  ];
}

class _Tip {
  const _Tip({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

class _SciTile {
  const _SciTile(
      {required this.icon, required this.title, required this.body});
  final String icon;
  final String title;
  final String body;
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});
  final _Tip tip;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tip.color.withAlpha(80)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tip.color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tip.icon, color: tip.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tip.title, style: AppTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(tip.body,
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ScienceTile extends StatelessWidget {
  const _ScienceTile({required this.tile});
  final _SciTile tile;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tile.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tile.title, style: AppTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(tile.body,
                      style: AppTheme.bodyMedium.copyWith(height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StatBubble extends StatelessWidget {
  const _StatBubble({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: AppTheme.labelSmall),
          ],
        ),
      );
}

class _EmptyRec extends StatelessWidget {
  const _EmptyRec();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lightbulb_outline_rounded,
                size: 56, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text('No insights yet', style: AppTheme.titleMedium),
            SizedBox(height: 6),
            Text(
              'Complete a few focus sessions\nto unlock personalised recommendations',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
}
