import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session_model.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/focus_chart.dart';

/// Compare focus scores across different study locations.
class EnvironmentComparisonScreen extends StatelessWidget {
  const EnvironmentComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<SessionProvider>().history;
    final scored = history.where((s) => s.score != null).toList();

    // Aggregate per location
    final Map<String, List<double>> byLocation = {};
    for (final s in scored) {
      byLocation.putIfAbsent(s.location, () => []).add(s.score!.total);
    }

    final Map<String, double> avgByLocation = {
      for (final e in byLocation.entries)
        e.key: e.value.reduce((a, b) => a + b) / e.value.length,
    };

    // Best location
    String? bestLocation;
    double bestScore = 0;
    avgByLocation.forEach((loc, score) {
      if (score > bestScore) {
        bestScore = score;
        bestLocation = loc;
      }
    });

    // Aggregates by time of day
    final Map<String, List<double>> byTime = {
      'Morning (6–12)': [],
      'Afternoon (12–17)': [],
      'Evening (17–22)': [],
      'Night (22–6)': [],
    };
    for (final s in scored) {
      final h = s.startTime.hour;
      if (h >= 6 && h < 12) {
        byTime['Morning (6–12)']!.add(s.score!.total);
      } else if (h >= 12 && h < 17) {
        byTime['Afternoon (12–17)']!.add(s.score!.total);
      } else if (h >= 17 && h < 22) {
        byTime['Evening (17–22)']!.add(s.score!.total);
      } else {
        byTime['Night (22–6)']!.add(s.score!.total);
      }
    }
    final Map<String, double> avgByTime = {
      for (final e in byTime.entries)
        if (e.value.isNotEmpty)
          e.key: e.value.reduce((a, b) => a + b) / e.value.length,
    };

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
                    const Text('Compare', style: AppTheme.displayLarge),
                    const SizedBox(height: 4),
                    Text('${scored.length} scored sessions analysed',
                        style: AppTheme.bodyMedium),
                  ],
                ),
              ),
            ),

            // ── Best location banner ──
            if (bestLocation != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _BestLocationCard(
                      location: bestLocation!, score: bestScore),
                ),
              ),

            // ── Location bar chart ──
            if (avgByLocation.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text('Average Score by Location',
                      style: AppTheme.headlineMedium),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: LocationBarChart(
                        data: avgByLocation, height: 220),
                  ),
                ),
              ),
            ],

            // ── Location detail rows ──
            if (avgByLocation.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text('Location Details',
                      style: AppTheme.headlineMedium),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final entry = avgByLocation.entries
                        .toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                    final loc  = entry[i].key;
                    final avg  = entry[i].value;
                    final cnt  = byLocation[loc]!.length;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: _LocationDetailCard(
                          location: loc,
                          avgScore: avg,
                          sessionCount: cnt,
                          sessions: scored
                              .where((s) => s.location == loc)
                              .toList()),
                    );
                  },
                  childCount: avgByLocation.length,
                ),
              ),
            ],

            // ── Time of day ──
            if (avgByTime.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text('Score by Time of Day',
                      style: AppTheme.headlineMedium),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    children: avgByTime.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TimeOfDayRow(label: e.key, score: e.value),
                    )).toList(),
                  ),
                ),
              ),
            ],

            // ── Empty state ──
            if (scored.isEmpty)
              const SliverFillRemaining(child: _EmptyComparison()),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _BestLocationCard extends StatelessWidget {
  const _BestLocationCard(
      {required this.location, required this.score});
  final String location;
  final double score;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.scoreColor(score);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(60), color.withAlpha(20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emoji_events_rounded, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Best Study Spot',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(location, style: AppTheme.titleLarge),
              ],
            ),
          ),
          Text(
            score.toStringAsFixed(0),
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: color),
          ),
        ],
      ),
    );
  }
}

class _LocationDetailCard extends StatelessWidget {
  const _LocationDetailCard({
    required this.location,
    required this.avgScore,
    required this.sessionCount,
    required this.sessions,
  });
  final String location;
  final double avgScore;
  final int sessionCount;
  final List<Session> sessions;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.scoreColor(avgScore);
    final avgNoise = sessions
            .where((s) => s.avgNoiseDb != null)
            .map((s) => s.avgNoiseDb!)
            .fold(0.0, (a, b) => a + b) /
        (sessions.where((s) => s.avgNoiseDb != null).length.clamp(1, 999));
    final avgLight = sessions
            .where((s) => s.avgLightLux != null)
            .map((s) => s.avgLightLux!)
            .fold(0.0, (a, b) => a + b) /
        (sessions.where((s) => s.avgLightLux != null).length.clamp(1, 999));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(location,
                    style: AppTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text(avgScore.toStringAsFixed(0),
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SmallStat(
                  icon: Icons.history_rounded,
                  label: '$sessionCount sessions'),
              const SizedBox(width: 12),
              _SmallStat(
                  icon: Icons.graphic_eq_rounded,
                  label: '${avgNoise.toStringAsFixed(0)} dB'),
              const SizedBox(width: 12),
              _SmallStat(
                  icon: Icons.wb_sunny_outlined,
                  label: '${avgLight.toStringAsFixed(0)} lux'),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: avgScore / 100,
              minHeight: 5,
              backgroundColor: AppTheme.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: AppTheme.labelSmall),
        ],
      );
}

class _TimeOfDayRow extends StatelessWidget {
  const _TimeOfDayRow({required this.label, required this.score});
  final String label;
  final double score;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.scoreColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTheme.bodyLarge)),
          Text(score.toStringAsFixed(0),
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: color, fontSize: 16)),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 6,
                backgroundColor: AppTheme.cardBorder,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyComparison extends StatelessWidget {
  const _EmptyComparison();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare_arrows_rounded,
                size: 56, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text('Not enough data yet', style: AppTheme.titleMedium),
            SizedBox(height: 6),
            Text(
              'Complete a few sessions in different\nlocations to see comparisons',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
}
