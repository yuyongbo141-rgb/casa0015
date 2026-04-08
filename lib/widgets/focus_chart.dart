import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/sensor_reading.dart';
import '../models/session_model.dart';
import '../theme/app_theme.dart';

// ── Score trend line chart ──────────────────────────────────────────────────

/// Sparkline of focus scores for the most recent [sessions] (oldest → newest).
class ScoreTrendChart extends StatelessWidget {
  const ScoreTrendChart({
    super.key,
    required this.sessions,
    this.height = 140,
    this.showLabels = false,
  });

  final List<Session> sessions;
  final double height;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final scored = sessions.where((s) => s.score != null).toList().reversed.toList();
    if (scored.isEmpty) {
      return SizedBox(
          height: height,
          child: const Center(
              child: Text('No data yet', style: TextStyle(color: AppTheme.textMuted))));
    }

    final spots = <FlSpot>[
      for (int i = 0; i < scored.length; i++)
        FlSpot(i.toDouble(), scored[i].score!.total),
    ];

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showLabels,
                reservedSize: 24,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= scored.length) return const SizedBox();
                  final d = scored[idx].startTime;
                  return Text('${d.day}/${d.month}',
                      style: AppTheme.labelSmall);
                },
              ),
            ),
          ),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppTheme.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: scored.length <= 10,
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: 3,
                  color: AppTheme.primary,
                  strokeColor: AppTheme.background,
                  strokeWidth: 1.5,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withAlpha(80),
                    AppTheme.primary.withAlpha(0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Location bar chart ──────────────────────────────────────────────────────

/// Horizontal bar chart comparing average focus score per location.
class LocationBarChart extends StatelessWidget {
  const LocationBarChart({
    super.key,
    required this.data, // {location: avgScore}
    this.height = 200,
  });

  final Map<String, double> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
          height: height,
          child: const Center(
              child: Text('No data yet',
                  style: TextStyle(color: AppTheme.textMuted))));
    }

    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final groups = <BarChartGroupData>[
      for (int i = 0; i < entries.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entries[i].value,
              width: 16,
              borderRadius: BorderRadius.circular(6),
              color: AppTheme.scoreColor(entries[i].value),
            ),
          ],
        ),
    ];

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          barGroups: groups,
          gridData: FlGridData(
            show: true,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppTheme.cardBorder,
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 25,
                getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                    style: AppTheme.labelSmall),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= entries.length) return const SizedBox();
                  final label = entries[idx].key;
                  // Abbreviate long names
                  final short = label.length > 8 ? '${label.substring(0, 7)}…' : label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(short,
                        style: AppTheme.labelSmall,
                        textAlign: TextAlign.center),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${entries[group.x].key}\n${rod.toY.toStringAsFixed(0)}',
                const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Live noise / movement mini-chart ───────────────────────────────────────

/// Small real-time line chart of recent sensor readings during a session.
class LiveSensorChart extends StatelessWidget {
  const LiveSensorChart({
    super.key,
    required this.readings,
    this.height = 80,
  });

  final List<SensorReading> readings;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) return SizedBox(height: height);

    final window = readings.length > 30 ? readings.sublist(readings.length - 30) : readings;

    final noiseSpots = <FlSpot>[
      for (int i = 0; i < window.length; i++)
        FlSpot(i.toDouble(), window[i].noiseDb),
    ];

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          minY: 20,
          maxY: 80,
          lineBarsData: [
            LineChartBarData(
              spots: noiseSpots,
              isCurved: true,
              color: AppTheme.secondary,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.secondary.withAlpha(40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
