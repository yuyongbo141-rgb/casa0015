import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

/// 4-page onboarding with animated transitions and permission request.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _pages = [
    _OPage(
      icon: Icons.shield_rounded,
      color: AppTheme.primary,
      title: 'Master Your\nStudy Environment',
      body:
          'FocusShield measures the world around you and tells you exactly what is helping or hurting your concentration.',
    ),
    _OPage(
      icon: Icons.sensors_rounded,
      color: AppTheme.secondary,
      title: 'Smart Sensing',
      body:
          'Your phone\'s sensors track ambient light, noise levels, and desk movement in real time — no extra hardware needed.',
    ),
    _OPage(
      icon: Icons.bar_chart_rounded,
      color: AppTheme.accent,
      title: 'Patterns Over Time',
      body:
          'After each session you receive a Focus Quality Score. Over days, the app reveals your best places, best times, and worst distractions.',
    ),
    _OPage(
      icon: Icons.lock_open_rounded,
      color: AppTheme.success,
      title: 'Quick Permissions',
      body:
          'FocusShield needs access to your microphone and motion sensors. All data stays on your device — nothing is uploaded.',
      isPermission: true,
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  Future<void> _finish() async {
    await context.read<SettingsProvider>().completeOnboarding();
    if (mounted) Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                child: TextButton(
                  onPressed: _skip,
                  child: const Text('Skip',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
              ),
            ),
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _PageContent(page: _pages[i]),
              ),
            ),
            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? AppTheme.primary
                              : AppTheme.cardBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(
                        _page == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OPage {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final bool isPermission;

  const _OPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.isPermission = false,
  });
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page});
  final _OPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon bubble
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withAlpha(30),
              shape: BoxShape.circle,
              border: Border.all(color: page.color.withAlpha(80), width: 2),
            ),
            child: Icon(page.icon, color: page.color, size: 54),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          if (page.isPermission) ...[
            const SizedBox(height: 32),
            _PermissionRow(
                icon: Icons.mic_none_rounded,
                label: 'Microphone',
                sub: 'For noise estimation'),
            const SizedBox(height: 12),
            _PermissionRow(
                icon: Icons.vibration_rounded,
                label: 'Motion Sensors',
                sub: 'Accelerometer & gyroscope'),
          ],
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow(
      {required this.icon, required this.label, required this.sub});

  final IconData icon;
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.success, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.titleMedium),
              Text(sub, style: AppTheme.bodyMedium),
            ],
          ),
          const Spacer(),
          const Icon(Icons.check_circle_rounded,
              color: AppTheme.success, size: 18),
        ],
      ),
    );
  }
}
