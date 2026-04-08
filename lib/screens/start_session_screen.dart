import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/settings_provider.dart';
import '../services/sensor_service.dart';
import '../models/sensor_reading.dart';
import '../theme/app_theme.dart';
import '../widgets/sensor_card.dart';
import '../services/scoring_engine.dart';

/// Configure and launch a new focus session.
class StartSessionScreen extends StatefulWidget {
  const StartSessionScreen({super.key});

  @override
  State<StartSessionScreen> createState() => _StartSessionScreenState();
}

class _StartSessionScreenState extends State<StartSessionScreen> {
  final _nameCtrl = TextEditingController(text: 'Study Session');
  String _location = 'University Library';
  double _goalMinutes = 45;
  SensorReading? _preview;
  SensorService? _previewSensor;

  static const _locations = [
    ('University Library', Icons.local_library_outlined),
    ('Home Desk', Icons.home_outlined),
    ('Coffee Shop', Icons.coffee_outlined),
    ('Study Room B', Icons.meeting_room_outlined),
    ('Bedroom', Icons.bed_outlined),
    ('Other', Icons.location_on_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _startPreview();
  }

  void _startPreview() {
    final useReal = context.read<SettingsProvider>().useRealSensors;
    _previewSensor = SensorService(useRealSensors: useReal);
    _previewSensor!.stream.listen((r) {
      if (mounted) setState(() => _preview = r);
    });
    _previewSensor!.start();
  }

  @override
  void dispose() {
    _previewSensor?.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    _previewSensor?.stop();
    final useReal = context.read<SettingsProvider>().useRealSensors;
    await context.read<SessionProvider>().startSession(
          name: _nameCtrl.text.trim().isEmpty ? 'Focus Session' : _nameCtrl.text.trim(),
          location: _location,
          goalMinutes: _goalMinutes.round(),
          useRealSensors: useReal,
        );
    if (mounted) Navigator.pushReplacementNamed(context, '/live');
  }

  @override
  Widget build(BuildContext context) {
    final scorer = const ScoringEngine();
    double lightScore = 50, noiseScore = 50, movScore = 50;
    if (_preview != null) {
      // Quick preview scores without duration
      lightScore = scorer.calculate(
              readings: [_preview!],
              sessionDuration: const Duration(minutes: 30))
          .lightScore;
      noiseScore = scorer.calculate(
              readings: [_preview!],
              sessionDuration: const Duration(minutes: 30))
          .noiseScore;
      movScore = scorer.calculate(
              readings: [_preview!],
              sessionDuration: const Duration(minutes: 30))
          .movementScore;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('New Session'),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Session name
          const Text('Session Name', style: AppTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'e.g. Essay Research',
              prefixIcon:
                  Icon(Icons.edit_outlined, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 24),

          // Location picker
          const Text('Location', style: AppTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _locations.map((loc) {
              final selected = _location == loc.$1;
              return GestureDetector(
                onTap: () => setState(() => _location = loc.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withAlpha(40)
                        : AppTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          selected ? AppTheme.primary : AppTheme.cardBorder,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(loc.$2,
                          size: 16,
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        loc.$1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Goal duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Goal Duration', style: AppTheme.titleMedium),
              Text(
                '${_goalMinutes.round()} min',
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _goalMinutes,
            min: 10,
            max: 120,
            divisions: 22,
            onChanged: (v) => setState(() => _goalMinutes = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('10 min', style: AppTheme.labelSmall),
              Text('60 min', style: AppTheme.labelSmall),
              Text('120 min', style: AppTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 28),

          // Live environment preview
          const Text('Current Environment', style: AppTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('Live readings from your device sensors',
              style: AppTheme.bodyMedium),
          const SizedBox(height: 12),
          if (_preview == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          else
            Column(
              children: [
                SensorCard(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Light Level',
                  value: _preview!.lightLux.toStringAsFixed(0),
                  unit: 'lux',
                  score: lightScore,
                ),
                const SizedBox(height: 10),
                SensorCard(
                  icon: Icons.graphic_eq_rounded,
                  label: 'Noise Level',
                  value: _preview!.noiseDb.toStringAsFixed(1),
                  unit: 'dB',
                  score: noiseScore,
                ),
                const SizedBox(height: 10),
                SensorCard(
                  icon: Icons.vibration_rounded,
                  label: 'Movement',
                  value: _preview!.movementMagnitude.toStringAsFixed(2),
                  unit: 'm/s²',
                  score: movScore,
                ),
              ],
            ),
          const SizedBox(height: 32),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Start ${_goalMinutes.round()} min Session'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
