import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

/// Persisted app preferences.  Notifies listeners on every change so the
/// UI rebuilds automatically (e.g. toggling demo mode refreshes dashboard).
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._storage);

  final StorageService _storage;

  // ── State ──────────────────────────────────────────────────────────────────

  bool   _demoMode          = true;   // on by default for first-run experience
  bool   _useRealSensors    = true;
  bool   _notificationsOn   = false;
  String _weatherApiKey     = '';
  bool   _hasOnboarded      = false;
  bool   _loaded            = false;

  // ── Getters ────────────────────────────────────────────────────────────────

  bool   get demoMode        => _demoMode;
  bool   get useRealSensors  => _useRealSensors;
  bool   get notificationsOn => _notificationsOn;
  String get weatherApiKey   => _weatherApiKey;
  bool   get hasOnboarded    => _hasOnboarded;
  bool   get isLoaded        => _loaded;

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> load() async {
    _hasOnboarded = await _storage.hasCompletedOnboarding();
    final s = await _storage.loadSettings();
    _demoMode        = s['demoMode']       as bool?   ?? true;
    _useRealSensors  = s['useRealSensors'] as bool?   ?? true;
    _notificationsOn = s['notifications']  as bool?   ?? false;
    _weatherApiKey   = s['weatherApiKey']  as String? ?? '';
    _loaded          = true;
    notifyListeners();
  }

  Future<void> _save() => _storage.saveSettings({
        'demoMode':       _demoMode,
        'useRealSensors': _useRealSensors,
        'notifications':  _notificationsOn,
        'weatherApiKey':  _weatherApiKey,
      });

  // ── Setters ────────────────────────────────────────────────────────────────

  Future<void> setDemoMode(bool v) async {
    _demoMode = v; notifyListeners(); await _save();
  }

  Future<void> setUseRealSensors(bool v) async {
    _useRealSensors = v; notifyListeners(); await _save();
  }

  Future<void> setNotifications(bool v) async {
    _notificationsOn = v; notifyListeners(); await _save();
  }

  Future<void> setWeatherApiKey(String v) async {
    _weatherApiKey = v; notifyListeners(); await _save();
  }

  Future<void> completeOnboarding() async {
    _hasOnboarded = true;
    notifyListeners();
    await _storage.setOnboardingComplete();
  }
}
