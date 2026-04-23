import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/session_model.dart' show Session;
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/session_card.dart';
import '../widgets/focus_chart.dart';

class HistoryAnalyticsScreen extends StatefulWidget {
  const HistoryAnalyticsScreen({super.key});

  @override
  State<HistoryAnalyticsScreen> createState() => _HistoryAnalyticsScreenState();
}

class _HistoryAnalyticsScreenState extends State<HistoryAnalyticsScreen> {
  int _filterDays = 7; // 7 | 30 | 0 (all)

  List<Session> _filtered(List<Session> sessions) {
    if (_filterDays == 0) return sessions;
    final cutoff = DateTime.now().subtract(Duration(days: _filterDays));
    return sessions.where((s) => s.startTime.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SessionProvider>();
    final all = sp.history;
    final shown = _filtered(all);
    final scored = shown.where((s) => s.score != null).toList();

    final avgScore = scored.isEmpty
        ? null
        : scored.map((s) => s.score!.total).reduce((a, b) => a + b) /
            scored.length;

    final bestScore =
        scored.isEmpty ? null : scored.map((s) => s.score!.total).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('History', style: AppTheme.displayLarge),
                    const SizedBox(height: 4),
                    Text('${all.length} sessions recorded',
                        style: AppTheme.bodyMedium),
                  ],
                ),
              ),
            ),

            // ── Filter chips ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Wrap(
                  spacing: 8,
                  children: [
                    _FilterChip(label: '7 days', value: 7, selected: _filterDays == 7,
                        onTap: () => setState(() => _filterDays = 7)),
                    _FilterChip(label: '30 days', value: 30, selected: _filterDays == 30,
                        onTap: () => setState(() => _filterDays = 30)),
                    _FilterChip(label: 'All time', value: 0, selected: _filterDays == 0,
                        onTap: () => setState(() => _filterDays = 0)),
                  ],
                ),
              ),
            ),

            // ── Stat cards ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                          label: 'Sessions',
                          value: shown.length.toString(),
                          icon: Icons.history_rounded,
                          color: AppTheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                          label: 'Avg Score',
                          value: avgScore?.toStringAsFixed(0) ?? '—',
                          icon: Icons.stars_rounded,
                          color: AppTheme.secondary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                          label: 'Best',
                          value: bestScore?.toStringAsFixed(0) ?? '—',
                          icon: Icons.emoji_events_rounded,
                          color: AppTheme.accent),
                    ),
                  ],
                ),
              ),
            ),

            // ── Score trend chart ──
            if (scored.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text('Score Trend', style: AppTheme.headlineMedium),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: ScoreTrendChart(
                      sessions: shown,
                      height: 160,
                      showLabels: true,
                    ),
                  ),
                ),
              ),
            ],

            // ── Heatmap calendar ──
            if (all.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text('Activity Calendar',
                      style: AppTheme.headlineMedium),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _HeatmapCalendar(sessions: all),
                ),
              ),
            ],

            // ── Session list ──
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text('All Sessions', style: AppTheme.headlineMedium),
              ),
            ),

            if (sp.isLoading)
              const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary)),
              )
            else if (shown.isEmpty)
              const SliverFillRemaining(child: _EmptyHistory())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: SessionCard(session: shown[i]),
                  ),
                  childCount: shown.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : AppTheme.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? AppTheme.primary : AppTheme.cardBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label, style: AppTheme.labelSmall),
          ],
        ),
      );
}

/// 4-week calendar grid where cell colour represents focus score.
class _HeatmapCalendar extends StatelessWidget {
  const _HeatmapCalendar({required this.sessions});
  final List sessions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(28, (i) => now.subtract(Duration(days: 27 - i)));

    // Map date string → avg score
    final Map<String, double> scoreMap = {};
    for (final s in sessions) {
      if (s.score == null) continue;
      final key = DateFormat('yyyy-MM-dd').format(s.startTime);
      final prev = scoreMap[key];
      scoreMap[key] = prev == null ? s.score!.total : (prev + s.score!.total) / 2;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          // Day-of-week labels
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) =>
              Expanded(child: Center(child: Text(d, style: AppTheme.labelSmall)))
            ).toList(),
          ),
          const SizedBox(height: 6),
          // Grid (4 weeks × 7 days)
          ...List.generate(4, (week) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: List.generate(7, (day) {
                final idx = week * 7 + day;
                if (idx >= days.length) return const Expanded(child: SizedBox());
                final date = days[idx];
                final key = DateFormat('yyyy-MM-dd').format(date);
                final score = scoreMap[key];
                final isToday = date.day == now.day &&
                    date.month == now.month &&
                    date.year == now.year;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: score != null
                              ? AppTheme.scoreColor(score).withAlpha(
                                  (score / 100 * 180 + 40).round())
                              : AppTheme.cardBorder.withAlpha(60),
                          borderRadius: BorderRadius.circular(5),
                          border: isToday
                              ? Border.all(color: AppTheme.primary, width: 1.5)
                              : null,
                        ),
                        child: score != null
                            ? Tooltip(
                                message:
                                    '${DateFormat('d MMM').format(date)}: ${score.toStringAsFixed(0)}',
                                child: const SizedBox.expand(),
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
          )),
          // Legend
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Low', style: AppTheme.labelSmall),
              const SizedBox(width: 4),
              ...List.generate(5, (i) {
                final score = (i + 1) * 20.0;
                return Container(
                  width: 14, height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.scoreColor(score).withAlpha(80 + i * 30),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
              const SizedBox(width: 4),
              const Text('High', style: AppTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 56, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text('No sessions in this period',
                style: AppTheme.titleMedium),
            SizedBox(height: 6),
            Text('Try a wider time range',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
}
