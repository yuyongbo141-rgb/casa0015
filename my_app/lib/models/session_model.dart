import 'sensor_reading.dart';
import 'focus_score.dart';

/// All data captured during and after one focus session.
class Session {
  final String id;
  final String name;
  final String location;
  final DateTime startTime;
  final DateTime? endTime;
  final int goalMinutes;

  /// Down-sampled readings stored for history analysis (max 180 points).
  final List<SensorReading> readings;

  /// Computed after the session ends; null while session is live.
  final FocusScore? score;

  /// Optional weather context fetched at session start.
  final String? weatherCondition; // e.g. "Partly Cloudy"
  final double? temperature;      // Celsius

  const Session({
    required this.id,
    required this.name,
    required this.location,
    required this.startTime,
    this.endTime,
    required this.goalMinutes,
    this.readings = const [],
    this.score,
    this.weatherCondition,
    this.temperature,
  });

  Duration get actualDuration =>
      (endTime ?? DateTime.now()).difference(startTime);

  bool get isComplete => endTime != null && score != null;

  /// Averages across all readings; returns null if no readings recorded.
  double? get avgLightLux => _avg((r) => r.lightLux);
  double? get avgNoiseDb  => _avg((r) => r.noiseDb);
  double? get avgMovement => _avg((r) => r.movementMagnitude);

  double? _avg(double Function(SensorReading) fn) {
    if (readings.isEmpty) return null;
    return readings.map(fn).reduce((a, b) => a + b) / readings.length;
  }

  Session copyWith({
    DateTime? endTime,
    List<SensorReading>? readings,
    FocusScore? score,
    String? weatherCondition,
    double? temperature,
  }) =>
      Session(
        id: id,
        name: name,
        location: location,
        startTime: startTime,
        endTime: endTime ?? this.endTime,
        goalMinutes: goalMinutes,
        readings: readings ?? this.readings,
        score: score ?? this.score,
        weatherCondition: weatherCondition ?? this.weatherCondition,
        temperature: temperature ?? this.temperature,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'goalMinutes': goalMinutes,
        'readings': readings.map((r) => r.toJson()).toList(),
        'score': score?.toJson(),
        'weatherCondition': weatherCondition,
        'temperature': temperature,
      };

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        id: j['id'] as String,
        name: j['name'] as String,
        location: j['location'] as String,
        startTime: DateTime.parse(j['startTime'] as String),
        endTime: j['endTime'] != null
            ? DateTime.parse(j['endTime'] as String)
            : null,
        goalMinutes: j['goalMinutes'] as int,
        readings: (j['readings'] as List<dynamic>? ?? [])
            .map((e) => SensorReading.fromJson(e as Map<String, dynamic>))
            .toList(),
        score: j['score'] != null
            ? FocusScore.fromJson(j['score'] as Map<String, dynamic>)
            : null,
        weatherCondition: j['weatherCondition'] as String?,
        temperature: (j['temperature'] as num?)?.toDouble(),
      );
}
