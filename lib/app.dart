import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'screens/start_session_screen.dart';
import 'screens/live_session_screen.dart';
import 'screens/end_session_report_screen.dart';

class FocusShieldApp extends StatelessWidget {
  const FocusShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch settings only for theme changes; route logic lives in screens
    final _ = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'FocusShield',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: '/',
      routes: {
        '/':             (_) => const SplashScreen(),
        '/onboarding':   (_) => const OnboardingScreen(),
        '/main':         (_) => const MainScreen(),
        '/start':        (_) => const StartSessionScreen(),
        '/live':         (_) => const LiveSessionScreen(),
        '/report':       (_) => const EndSessionReportScreen(),
      },
    );
  }
}
