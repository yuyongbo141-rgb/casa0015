import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/sensor_reading.dart';

/// Abstracts all environmental sensors with graceful simulation fallback.
///
/// Real accelerometer data is read from sensors_plus; light and noise are
/// simulated (light sensor not universally available; mic requires custom
/// native plugin beyond scope).  Simulation uses a random-walk model to
/// produce realistic variation matching typical study environments.
class SensorService {
  SensorService({this.useRealSensors = true});

  final bool useRealSensors;
  final _rng = Random();

  // Live sensor state
  double _lightLux    = 380.0;
  double _noiseDb     = 36.0;
  double _accelX      = 0.0;
  double _accelY      = 0.0;
  double _accelZ      = 9.81; // gravity at rest

  StreamSubscription<AccelerometerEvent>? _accelSub;
  Timer? _ticker;

  final _controller = StreamController<SensorReading>.broadcast();

  /// Emits a new [SensorReading] every 2 seconds.
  Stream<SensorReading> get stream => _controller.stream;

  /// Begin sampling.  Call [stop] when the session ends.
  void start() {
    // Real accelerometer ─ falls back silently on unsupported platforms
    if (useRealSensors) {
      try {
        _accelSub = accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 500),
        ).listen((event) {
          _accelX = event.x;
          _accelY = event.y;
          _accelZ = event.z;
        });
      } catch (_) {
        // Platform doesn't support accelerometer – continue with simulation
      }
    }

    // Tick every 2 s, simulate light/noise, emit reading
    _ticker = Timer.periodic(const Duration(seconds: 2), (_) {
      _simulateStep();
      _controller.add(_snapshot());
    });
  }

  void stop() {
    _accelSub?.cancel();
    _ticker?.cancel();
    _accelSub = null;
    _ticker   = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }

  /// Returns the most recent reading without waiting for the next tick.
  SensorReading currentReading() => _snapshot();

  // ── Simulation ─────────────────────────────────────────────────────────────

  /// Random-walk simulation: values drift slowly around a baseline that
  /// shifts with time-of-day to mimic realistic study conditions.
  void _simulateStep() {
    final hour = DateTime.now().hour;

    // Light: daytime baseline 400 lux, evening 180 lux, night 120 lux
    final lightBaseline = hour >= 8 && hour < 18
        ? 420.0
        : hour >= 18 && hour < 22
            ? 200.0
            : 130.0;
    _lightLux = (_lightLux + _rng.nextDouble() * 40 - 20)
        .clamp(lightBaseline - 150, lightBaseline + 200);

    // Noise: occasional spikes simulate conversation bursts
    final noiseDrift = _rng.nextDouble() < 0.08 ? 18.0 : 0.0; // 8 % spike
    _noiseDb = (_noiseDb + _rng.nextDouble() * 6 - 3 + noiseDrift)
        .clamp(28.0, 75.0);

    // Accel: small random drift if not using real sensor
    if (!useRealSensors || _accelSub == null) {
      final move = _rng.nextDouble() < 0.05 ? _rng.nextDouble() * 3 : 0.0;
      _accelX = _rng.nextDouble() * 0.1 - 0.05 + move;
      _accelY = _rng.nextDouble() * 0.1 - 0.05;
      _accelZ = 9.81 + _rng.nextDouble() * 0.1 - 0.05;
    }
  }

  SensorReading _snapshot() => SensorReading(
        timestamp: DateTime.now(),
        lightLux: _lightLux,
        noiseDb: _noiseDb,
        accelX: _accelX,
        accelY: _accelY,
        accelZ: _accelZ,
      );
}
