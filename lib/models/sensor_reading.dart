import 'dart:math';

/// A single time-stamped snapshot of all environmental sensors.
/// Readings are collected every 2 s during a live focus session.
class SensorReading {
  final DateTime timestamp;

  /// Ambient light level in lux (simulated if hardware unavailable).
  final double lightLux;

  /// Estimated noise level in dB SPL (simulated via mic RMS approximation).
  final double noiseDb;

  /// Raw accelerometer axes (m/s²).
  final double accelX;
  final double accelY;
  final double accelZ;

  SensorReading({
    required this.timestamp,
    required this.lightLux,
    required this.noiseDb,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
  });

  /// Combined magnitude of acceleration (minus gravity baseline).
  double get movementMagnitude {
    final mag = sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);
    return (mag - 9.81).abs(); // deviation from gravitational rest
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'lightLux': lightLux,
        'noiseDb': noiseDb,
        'accelX': accelX,
        'accelY': accelY,
        'accelZ': accelZ,
      };

  factory SensorReading.fromJson(Map<String, dynamic> j) => SensorReading(
        timestamp: DateTime.parse(j['timestamp'] as String),
        lightLux: (j['lightLux'] as num).toDouble(),
        noiseDb: (j['noiseDb'] as num).toDouble(),
        accelX: (j['accelX'] as num).toDouble(),
        accelY: (j['accelY'] as num).toDouble(),
        accelZ: (j['accelZ'] as num).toDouble(),
      );
}
