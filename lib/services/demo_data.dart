import 'dart:math';
import '../models/session_model.dart';
import '../models/sensor_reading.dart';
import '../models/focus_score.dart';

/// Generates 14 days of realistic seeded demo sessions.
/// Used when the user first launches or enables Demo Mode in Settings.
class DemoData {
  static final _rng = Random(42); // fixed seed for reproducibility

  static const _locations = [
    'University Library',
    'Home Desk',
    'Coffee Shop',
    'Study Room B',
    'Bedroom',
  ];

  static const _sessionNames = [
    'Essay Research',
    'Lecture Notes',
    'Problem Sheet 3',
    'Dissertation Writing',
    'Exam Revision',
    'Group Project',
    'Reading Week',
    'Lab Report',
  ];

  static const _weather = [
    ('Clear', 18.0),
    ('Clouds', 14.0),
    ('Rain', 11.0),
    ('Clouds', 16.0),
    ('Clear', 21.0),
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  static List<Session> generate() {
    final now = DateTime.now();
    final sessions = <Session>[];

    for (int day = 13; day >= 0; day--) {
      final date = now.subtract(Duration(days: day));
      final count = _rng.nextInt(2) + 1; // 1–2 sessions per day
      for (int s = 0; s < count; s++) {
        sessions.add(_buildSession(date, s));
      }
    }

    return sessions;
  }

  // ── Builders ───────────────────────────────────────────────────────────────

  static Session _buildSession(DateTime date, int index) {
    final location = _locations[_rng.nextInt(_locations.length)];
    final name     = _sessionNames[_rng.nextInt(_sessionNames.length)];
    final weather  = _weather[_rng.nextInt(_weather.length)];

    // Morning or afternoon start
    final startHour  = index == 0 ? 9 + _rng.nextInt(3) : 14 + _rng.nextInt(4);
    final startMin   = _rng.nextInt(60);
    final start      = DateTime(date.year, date.month, date.day, startHour, startMin);
    final durationMin = 20 + _rng.nextInt(70); // 20–89 min
    final end = start.add(Duration(minutes: durationMin));

    final readings = _buildReadings(start, durationMin, location);
    final score    = _buildScore(readings, durationMin, location);

    return Session(
      id: '${start.millisecondsSinceEpoch}_$index',
      name: name,
      location: location,
      startTime: start,
      endTime: end,
      goalMinutes: 45,
      readings: readings,
      score: score,
      weatherCondition: weather.$1,
      temperature: weather.$2,
    );
  }

  static List<SensorReading> _buildReadings(
    DateTime start,
    int durationMin,
    String location,
  ) {
    // Characterise each location with a noise/light profile
    final (lightBase, noiseBase) = _locationProfile(location);
    final readings = <SensorReading>[];
    final totalTicks = (durationMin * 60 / 2).floor(); // one reading per 2 s

    // Down-sample to max 60 stored readings per session
    final step = max(1, totalTicks ~/ 60);

    double light = lightBase + _rng.nextDouble() * 40 - 20;
    double noise = noiseBase + _rng.nextDouble() * 6 - 3;

    for (int i = 0; i < totalTicks; i += step) {
      light = (light + _rng.nextDouble() * 20 - 10).clamp(
        lightBase - 80, lightBase + 120);
      noise = (noise + _rng.nextDouble() * 5 - 2.5 +
          (_rng.nextDouble() < 0.06 ? 15 : 0)).clamp(noiseBase - 10, 75);

      final move = _rng.nextDouble() < 0.04 ? _rng.nextDouble() * 2.5 : 0.0;
      readings.add(SensorReading(
        timestamp: start.add(Duration(seconds: i * 2)),
        lightLux: light,
        noiseDb: noise,
        accelX: _rng.nextDouble() * 0.08 - 0.04 + move,
        accelY: _rng.nextDouble() * 0.08 - 0.04,
        accelZ: 9.81 + _rng.nextDouble() * 0.05,
      ));
    }
    return readings;
  }

  static FocusScore _buildScore(
    List<SensorReading> readings,
    int durationMin,
    String location,
  ) {
    // Compute realistic scores – library should beat bedroom
    final (_, noiseBase) = _locationProfile(location);
    final noiseFactor = (75.0 - noiseBase) / 45.0; // 0-1

    final total = (45 + noiseFactor * 40 + _rng.nextDouble() * 15)
        .clamp(40.0, 97.0);

    return FocusScore(
      total: total,
      lightScore: (55 + _rng.nextDouble() * 35).clamp(0, 100),
      noiseScore: (noiseFactor * 100).clamp(20, 100),
      movementScore: (60 + _rng.nextDouble() * 35).clamp(0, 100),
      durationScore: durationMin >= 50 ? 90 : (durationMin / 50 * 90),
      positives: total > 70
          ? ['Quiet surroundings', 'Good lighting']
          : ['Session completed'],
      negatives: total < 60 ? ['Noisy environment'] : [],
      recommendations: ['Try noise-cancelling headphones if score dips'],
    );
  }

  static (double light, double noise) _locationProfile(String location) {
    switch (location) {
      case 'University Library': return (420, 32);
      case 'Home Desk':          return (380, 38);
      case 'Study Room B':       return (400, 35);
      case 'Coffee Shop':        return (310, 58);
      case 'Bedroom':            return (230, 42);
      default:                   return (350, 40);
    }
  }
}
