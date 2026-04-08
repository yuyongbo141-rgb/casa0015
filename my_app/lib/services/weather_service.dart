import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches current weather from OpenWeatherMap.
/// Falls back to plausible mock data when the key is absent or the call fails.
class WeatherService {
  WeatherService({this.apiKey = ''});

  final String apiKey;

  /// Returns a [WeatherInfo] for the given lat/lon or falls back to mock.
  Future<WeatherInfo> fetchWeather({
    double lat = 51.5074,
    double lon = -0.1278,
  }) async {
    if (apiKey.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather'
          '?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
        );
        final response = await http.get(uri).timeout(const Duration(seconds: 6));
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final weather = (data['weather'] as List).first as Map<String, dynamic>;
          final main = data['main'] as Map<String, dynamic>;
          return WeatherInfo(
            condition: weather['main'] as String,
            description: weather['description'] as String,
            temperature: (main['temp'] as num).toDouble(),
            humidity: (main['humidity'] as num).toInt(),
            icon: weather['icon'] as String,
          );
        }
      } catch (_) {
        // network or parse error – use mock
      }
    }
    return _mockWeather();
  }

  /// Deterministic mock so the UI always shows something sensible.
  WeatherInfo _mockWeather() {
    final hour = DateTime.now().hour;
    final isMorning = hour >= 6 && hour < 12;
    final isEvening = hour >= 18;
    return WeatherInfo(
      condition: isMorning ? 'Clear' : isEvening ? 'Clouds' : 'Partly Cloudy',
      description: isMorning ? 'clear sky' : isEvening ? 'overcast' : 'scattered clouds',
      temperature: isMorning ? 16 : isEvening ? 13 : 18,
      humidity: 62,
      icon: isMorning ? '01d' : isEvening ? '04n' : '02d',
    );
  }
}

class WeatherInfo {
  final String condition;
  final String description;
  final double temperature;
  final int humidity;
  final String icon;

  const WeatherInfo({
    required this.condition,
    required this.description,
    required this.temperature,
    required this.humidity,
    required this.icon,
  });

  /// Simple emoji representative of the condition for offline display.
  String get emoji {
    switch (condition.toLowerCase()) {
      case 'clear':       return '☀️';
      case 'clouds':      return '☁️';
      case 'rain':        return '🌧️';
      case 'drizzle':     return '🌦️';
      case 'thunderstorm':return '⛈️';
      case 'snow':        return '❄️';
      case 'mist':
      case 'fog':         return '🌫️';
      default:            return '🌤️';
    }
  }
}
