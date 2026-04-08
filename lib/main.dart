import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/session_provider.dart';
import 'providers/settings_provider.dart';
import 'services/storage_service.dart';
import 'services/weather_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait for consistent demo experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final storage = StorageService();
  final weather = WeatherService(); // apiKey injected from settings later

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storage)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => SessionProvider(storage, weather),
        ),
      ],
      child: const FocusShieldApp(),
    ),
  );
}
