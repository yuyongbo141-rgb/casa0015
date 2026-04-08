import '../models/sensor_reading.dart';
import '../models/focus_score.dart';

/// Computes a Focus Quality Score (0–100) from a completed session's data.
///
/// Weight allocation:
///   Noise     40 % – loudest predictor of concentration disruption
///   Movement  25 % – phone pickup / desk vibration frequency
///   Light     20 % – ergonomic reading conditions
///   Duration  15 % – bonus for sustained effort
class ScoringEngine {
  const ScoringEngine();

  FocusScore calculate({
    required List<SensorReading> readings,
    required Duration sessionDuration,
  }) {
    final light    = _lightScore(readings);
    final noise    = _noiseScore(readings);
    final movement = _movementScore(readings);
    final duration = _durationScore(sessionDuration);

    final total =
        (light    * 0.20) +
        (noise    * 0.40) +
        (movement * 0.25) +
        (duration * 0.15);

    return FocusScore(
      total: total.clamp(0, 100),
      lightScore: light,
      noiseScore: noise,
      movementScore: movement,
      durationScore: duration,
      positives: _positives(light, noise, movement, duration),
      negatives: _negatives(light, noise, movement, sessionDuration),
      recommendations: _recommendations(light, noise, movement),
    );
  }

  // ── Sub-score calculators ──────────────────────────────────────────────────

  double _lightScore(List<SensorReading> readings) {
    if (readings.isEmpty) return 50;
    final avg = _mean(readings.map((r) => r.lightLux));
    // Optimal: 300–600 lux (library / desk lamp range)
    if (avg < 50)   return 25;
    if (avg < 150)  return 45 + (avg - 50) / 100 * 15;   // 45-60
    if (avg < 300)  return 60 + (avg - 150) / 150 * 20;  // 60-80
    if (avg <= 600) return 80 + (1 - (avg - 300).abs() / 300) * 20; // 80-100
    if (avg <= 900) return 70 - (avg - 600) / 300 * 20;  // 70-50
    return 40; // very bright / glare
  }

  double _noiseScore(List<SensorReading> readings) {
    if (readings.isEmpty) return 50;
    final avg = _mean(readings.map((r) => r.noiseDb));
    // Library quiet ≈ 30 dB; conversation ≈ 60 dB; loud café ≈ 70 dB
    if (avg <= 30) return 100;
    if (avg <= 45) return 100 - (avg - 30) / 15 * 25; // 100-75
    if (avg <= 60) return 75  - (avg - 45) / 15 * 35; // 75-40
    if (avg <= 75) return 40  - (avg - 60) / 15 * 30; // 40-10
    return 5;
  }

  double _movementScore(List<SensorReading> readings) {
    if (readings.isEmpty) return 50;
    final avg = _mean(readings.map((r) => r.movementMagnitude));
    // Movement magnitude: 0 = completely still, 5+ = frequent disturbance
    if (avg < 0.2) return 100;
    if (avg < 0.5) return 90 - (avg - 0.2) / 0.3 * 15;
    if (avg < 1.5) return 75 - (avg - 0.5) / 1.0 * 35;
    if (avg < 3.0) return 40 - (avg - 1.5) / 1.5 * 30;
    return 5;
  }

  double _durationScore(Duration d) {
    final mins = d.inMinutes;
    if (mins < 10)  return 10;
    if (mins < 25)  return 10 + (mins - 10) / 15 * 30; // 10-40
    if (mins < 50)  return 40 + (mins - 25) / 25 * 40; // 40-80
    if (mins < 90)  return 80 + (mins - 50) / 40 * 20; // 80-100
    return 95; // very long session – slight diminishing return
  }

  // ── Insight text generators ────────────────────────────────────────────────

  List<String> _positives(double l, double n, double m, double d) {
    final out = <String>[];
    if (l >= 70) out.add('Well-lit environment supported reading comfort');
    if (n >= 75) out.add('Quiet surroundings minimised distraction');
    if (m >= 80) out.add('Phone stayed still – great self-discipline');
    if (d >= 80) out.add('Strong sustained session (≥ 50 min)');
    return out;
  }

  List<String> _negatives(double l, double n, double m, Duration d) {
    final out = <String>[];
    if (l < 40)  out.add('Low light may have caused eye strain');
    if (n < 50)  out.add('Noisy environment interrupted focus flow');
    if (m < 40)  out.add('Frequent phone movement detected');
    if (d.inMinutes < 20) out.add('Short session – consider Pomodoro blocks');
    return out;
  }

  List<String> _recommendations(double l, double n, double m) {
    final out = <String>[];
    if (l < 60)  out.add('Add a desk lamp to reach 300–600 lux');
    if (n < 60)  out.add('Try noise-cancelling headphones or a quieter room');
    if (m < 60)  out.add('Place phone face-down or use Do Not Disturb mode');
    if (out.isEmpty) out.add('Keep up these excellent study conditions!');
    return out;
  }

  double _mean(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b) / list.length;
  }
}
