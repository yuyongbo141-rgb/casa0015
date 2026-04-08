import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';

/// App settings: demo mode, sensors, API keys, data management, privacy.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyCtrl = TextEditingController();
  bool _showApiKey  = false;

  @override
  void initState() {
    super.initState();
    final key = context.read<SettingsProvider>().weatherApiKey;
    _apiKeyCtrl.text = key;
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmClearData() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Clear all data?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'This permanently deletes all sessions and cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<SessionProvider>().reloadDemo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data cleared and demo data reloaded'),
            backgroundColor: AppTheme.card,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Header ──
            const Text('Settings', style: AppTheme.displayLarge),
            const SizedBox(height: 24),

            // ── Behaviour ──
            _SectionHeader(label: 'BEHAVIOUR'),
            _SettingsTile(
              icon: Icons.science_outlined,
              iconColor: AppTheme.accent,
              title: 'Demo Mode',
              subtitle: 'Show seeded sample sessions',
              trailing: Switch(
                value: settings.demoMode,
                onChanged: (v) async {
                  final sp = context.read<SessionProvider>();
                  await settings.setDemoMode(v);
                  if (!mounted) return;
                  await sp.loadHistory(demoMode: v);
                },
              ),
            ),
            _SettingsTile(
              icon: Icons.sensors_rounded,
              iconColor: AppTheme.primary,
              title: 'Real Sensors',
              subtitle: 'Use device accelerometer during sessions',
              trailing: Switch(
                value: settings.useRealSensors,
                onChanged: settings.setUseRealSensors,
              ),
            ),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              iconColor: AppTheme.secondary,
              title: 'Focus Reminders',
              subtitle: 'Daily nudges to start a session',
              trailing: Switch(
                value: settings.notificationsOn,
                onChanged: settings.setNotifications,
              ),
            ),

            const SizedBox(height: 20),

            // ── Integrations ──
            _SectionHeader(label: 'INTEGRATIONS'),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text('OpenWeatherMap API Key',
                  style: AppTheme.bodyMedium),
            ),
            TextField(
              controller: _apiKeyCtrl,
              obscureText: !_showApiKey,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Leave blank for mock weather',
                suffixIcon: IconButton(
                  icon: Icon(
                      _showApiKey
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.textSecondary,
                      size: 18),
                  onPressed: () => setState(() => _showApiKey = !_showApiKey),
                ),
              ),
              onSubmitted: (v) => settings.setWeatherApiKey(v.trim()),
            ),
            const SizedBox(height: 6),
            Text(
              'Get a free key at openweathermap.org/api — used only for the live weather widget.',
              style: AppTheme.labelSmall.copyWith(height: 1.5),
            ),

            const SizedBox(height: 20),

            // ── Data ──
            _SectionHeader(label: 'DATA & PRIVACY'),
            _SettingsTile(
              icon: Icons.storage_outlined,
              iconColor: AppTheme.textSecondary,
              title: 'Storage',
              subtitle: 'All data stored locally on this device',
              trailing: const Icon(Icons.lock_outline_rounded,
                  color: AppTheme.success, size: 20),
            ),
            _SettingsTile(
              icon: Icons.cloud_off_outlined,
              iconColor: AppTheme.textSecondary,
              title: 'No cloud sync',
              subtitle: 'Sessions never leave your phone',
              trailing: const Icon(Icons.check_circle_outline_rounded,
                  color: AppTheme.success, size: 20),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error),
              ),
              onPressed: _confirmClearData,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Clear All Session Data'),
            ),

            const SizedBox(height: 28),

            // ── About ──
            _SectionHeader(label: 'ABOUT'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shield_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FocusShield', style: AppTheme.titleLarge),
                          Text('Version 1.0.0',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Built with Flutter for the CASA Connected Environment '
                    'mobile assessment. Combines on-device sensors with '
                    'contextual APIs to help students understand and improve '
                    'their study environment quality.',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.55),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: const [
                      _TagChip('Flutter'),
                      _TagChip('Dart'),
                      _TagChip('sensors_plus'),
                      _TagChip('fl_chart'),
                      _TagChip('Provider'),
                      _TagChip('SharedPreferences'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label, style: AppTheme.labelSmall),
      );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.titleMedium),
                  Text(subtitle, style: AppTheme.bodyMedium),
                ],
              ),
            ),
            trailing,
          ],
        ),
      );
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primary.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withAlpha(60)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.primary,
                fontWeight: FontWeight.w500)),
      );
}
