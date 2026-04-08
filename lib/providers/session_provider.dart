import 'package:flutter/foundation.dart';
import '../models/session_model.dart';
import '../models/sensor_reading.dart';
import '../services/sensor_service.dart';
import '../services/storage_service.dart';
import '../services/scoring_engine.dart';
import '../services/demo_data.dart';
import '../services/weather_service.dart';

enum SessionState { idle, running, paused, finished }

/// Central state owner for session lifecycle and history.
class SessionProvider extends ChangeNotifier {
  SessionProvider(this._storage, this._weather);

  final StorageService _storage;
  final WeatherService _weather;
  final _scorer = const ScoringEngine();

  // ── Live session state ─────────────────────────────────────────────────────
  Session?      _current;
  SessionState  _sessionState = SessionState.idle;
  SensorService? _sensors;
  final List<SensorReading> _liveReadings = [];

  // ── History ────────────────────────────────────────────────────────────────
  List<Session> _history = [];
  bool _historyLoaded = false;
  bool _isLoading     = false;
  String? _error;

  // ── Getters ────────────────────────────────────────────────────────────────
  Session?      get current       => _current;
  SessionState  get sessionState  => _sessionState;
  List<SensorReading> get liveReadings => List.unmodifiable(_liveReadings);
  List<Session> get history       => List.unmodifiable(_history);
  bool          get isLoading     => _isLoading;
  String?       get error         => _error;

  /// Most recent sensor snapshot (null before first tick).
  SensorReading? get latestReading =>
      _liveReadings.isEmpty ? null : _liveReadings.last;

  // ── History loading ────────────────────────────────────────────────────────

  Future<void> loadHistory({bool demoMode = false}) async {
    if (_historyLoaded && !demoMode) return;
    _isLoading = true; notifyListeners();

    try {
      var saved = await _storage.loadSessions();

      if (demoMode && saved.isEmpty) {
        // Seed demo data on first launch or when demo mode toggled on
        saved = DemoData.generate();
        await _storage.saveSessions(saved);
      }

      // Sort newest first for the history list
      _history = saved..sort((a, b) => b.startTime.compareTo(a.startTime));
      _historyLoaded = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> reloadDemo() async {
    _historyLoaded = false;
    await _storage.clearSessions();
    await loadHistory(demoMode: true);
  }

  // ── Session lifecycle ──────────────────────────────────────────────────────

  Future<void> startSession({
    required String name,
    required String location,
    required int goalMinutes,
    required bool useRealSensors,
  }) async {
    _liveReadings.clear();

    // Fetch weather context (non-blocking – we don't await to fail)
    WeatherInfo? wx;
    try { wx = await _weather.fetchWeather(); } catch (_) {}

    _current = Session(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      location: location,
      startTime: DateTime.now(),
      goalMinutes: goalMinutes,
      weatherCondition: wx?.condition,
      temperature: wx?.temperature,
    );

    _sensors = SensorService(useRealSensors: useRealSensors);
    _sensors!.stream.listen(_onReading);
    _sensors!.start();

    _sessionState = SessionState.running;
    notifyListeners();
  }

  void pauseSession() {
    _sensors?.stop();
    _sessionState = SessionState.paused;
    notifyListeners();
  }

  void resumeSession() {
    _sensors?.start();
    _sessionState = SessionState.running;
    notifyListeners();
  }

  /// Ends the session, computes the score, and persists.
  Future<Session> endSession() async {
    _sensors?.stop();
    final now = DateTime.now();

    final score = _scorer.calculate(
      readings: _liveReadings,
      sessionDuration: now.difference(_current!.startTime),
    );

    final completed = _current!.copyWith(
      endTime: now,
      readings: List.from(_liveReadings),
      score: score,
    );

    _history.insert(0, completed);
    await _storage.saveSessions(_history);

    _current = completed;
    _sessionState = SessionState.finished;
    notifyListeners();
    return completed;
  }

  void resetSession() {
    _sensors?.dispose();
    _sensors = null;
    _current = null;
    _liveReadings.clear();
    _sessionState = SessionState.idle;
    notifyListeners();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _onReading(SensorReading r) {
    _liveReadings.add(r);
    notifyListeners();
  }

  @override
  void dispose() {
    _sensors?.dispose();
    super.dispose();
  }
}
