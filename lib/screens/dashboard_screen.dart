import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/settings_provider.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../widgets/session_card.dart';
import '../widgets/focus_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  WeatherInfo? _weather;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final key = context.read<SettingsProvider>().weatherApiKey;
    final wx = await WeatherService(apiKey: key).fetchWeather();
    if (mounted) setState(() => _weather = wx);
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SessionProvider>();
    final history = sp.history;
    final recent = history.take(3).toList();
    final weekSessions = history
        .where((s) =>
            s.startTime.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList();

    final avgScore = weekSessions.isEmpty
        ? null
        : weekSessions
                .where((s) => s.score != null)
                .map((s) => s.score!.total)
                .fold(0.0, (a, b) => a + b) /
            weekSessions.where((s) => s.score != null).length;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          backgroundColor: AppTheme.card,
          onRefresh: () => sp.loadHistory(
              demoMode: context.read<SettingsProvider>().demoMode),
          child: CustomScrollView(
            slivers: [
              // ── App bar ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(greeting,
                              style: AppTheme.bodyMedium),
                          const SizedBox(height: 2),
                          const Text('FocusShield',
                              style: AppTheme.displayLarge),
                        ],
                      ),
                      const Spacer(),
                      if (_weather != null)
                        _WeatherChip(weather: _weather!),
                    ],
                  ),
                ),
              ),

              // ── Weekly summary card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _WeeklySummaryCard(
                    avgScore: avgScore,
                    sessionCount: weekSessions.length,
                    sessions: weekSessions,
                  ),
                ),
              ),

              // ── Quick-start CTA ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _StartSessionBanner(
                    onTap: () => Navigator.pushNamed(context, '/start'),
                  ),
                ),
              ),

              // ── Recent sessions ──
              if (recent.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                    child: Text('Recent Sessions',
                        style: AppTheme.headlineMedium),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: SessionCard(session: recent[i]),
                    ),
                    childCount: recent.length,
                  ),
                ),
              ],

              // ── Empty state ──
              if (history.isEmpty && !sp.isLoading)
                const SliverFillRemaining(
                  child: Center(child: _EmptyState()),
                ),

              // ── Loading ──
              if (sp.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),

              // ── Tip of the day ──
              if (!sp.isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: _TipCard(sessions: history),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _WeatherChip extends StatelessWidget {
  const _WeatherChip({required this.weather});
  final WeatherInfo weather;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(weather.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            '${weather.temperature.toStringAsFixed(0)}°C',
            style: AppTheme.titleMedium,
          ),
          const SizedBox(width: 4),
          Text(weather.condition, style: AppTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard({
    required this.avgScore,
    required this.sessionCount,
    required this.sessions,
  });

  final double? avgScore;
  final int sessionCount;
  final List sessions;

  @override
  Widget build(BuildContext context) {
    final color = avgScore != null
        ? AppTheme.scoreColor(avgScore!)
        : AppTheme.textMuted;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('This Week', style: AppTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        avgScore?.toStringAsFixed(0) ?? '—',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: color,
                          height: 1,
                        ),
                      ),
                      if (avgScore != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6, left: 4),
                          child: Text('avg score',
                              style: AppTheme.bodyMedium),
                        ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$sessionCount', style: AppTheme.displayLarge),
                  const Text('sessions', style: AppTheme.bodyMedium),
                ],
              ),
            ],
          ),
          if (sessions.isNotEmpty) ...[
            const SizedBox(height: 16),
            ScoreTrendChart(sessions: List.from(sessions), height: 70),
          ],
        ],
      ),
    );
  }
}

class _StartSessionBanner extends StatelessWidget {
  const _StartSessionBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ready to Focus?',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  SizedBox(height: 4),
                  Text('Start a session and track your environment',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          height: 1.4)),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.sessions});
  final List sessions;

  static const _tips = [
    ('🌿', 'Plants reduce stress', 'Adding greenery to your workspace can lower cortisol and improve mood.'),
    ('🎧', 'White noise works', 'Ambient noise at ~65 dB (café level) can boost creative thinking.'),
    ('💡', 'Optimal lighting', 'Aim for 300–600 lux warm-white light to reduce eye strain.'),
    ('📵', 'Silence your phone', 'Visible phone notifications reduce focus by up to 20 %.'),
    ('⏱️', 'Pomodoro technique', 'Work 25 min, rest 5 min. Repeat. Your brain needs recovery cycles.'),
    ('🌡️', 'Room temperature', 'Cognitive performance peaks at 22–24 °C — check your thermostat.'),
  ];

  @override
  Widget build(BuildContext context) {
    final idx = DateTime.now().day % _tips.length;
    final tip = _tips[idx];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Text(tip.$1, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 13, color: AppTheme.accent),
                  const SizedBox(width: 4),
                  const Text('Tip of the Day',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8)),
                ]),
                const SizedBox(height: 4),
                Text(tip.$2, style: AppTheme.titleMedium),
                const SizedBox(height: 2),
                Text(tip.$3,
                    style: AppTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.auto_graph_rounded,
            size: 64, color: AppTheme.textMuted),
        const SizedBox(height: 16),
        const Text('No sessions yet', style: AppTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Start a focus session to begin\ntracking your study environment',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/start'),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Start First Session'),
        ),
      ],
    );
  }
}
