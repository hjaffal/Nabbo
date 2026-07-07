import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';

/// Simple weather data from OpenWeatherMap
class WeatherData {
  final double temperature; // Celsius
  final String icon; // OpenWeatherMap icon code
  final String description; // e.g. "clear sky"
  final String? cityName; // city name from API response

  WeatherData({
    required this.temperature,
    required this.icon,
    required this.description,
    this.cityName,
  });

  /// Returns a weather emoji based on icon code
  String get emoji => switch (icon) {
        '01d' => '☀️',
        '01n' => '🌙',
        '02d' || '02n' => '⛅',
        '03d' || '03n' => '☁️',
        '04d' || '04n' => '☁️',
        '09d' || '09n' => '🌧️',
        '10d' || '10n' => '🌦️',
        '11d' || '11n' => '⛈️',
        '13d' || '13n' => '❄️',
        '50d' || '50n' => '🌫️',
        _ => '🌤️',
      };
}

/// Fetches current weather from OpenWeatherMap API
class WeatherService {
  // OpenWeatherMap free tier API key
  static const _apiKey = ApiKeys.weatherApiKey;

  /// Fetch weather by city name
  static Future<WeatherData?> fetchByCity(String city) async {
    if (city.isEmpty) return null;
    try {
      // Try full city string first
      var weather = await _fetchCity(city);
      if (weather != null) return weather;

      // Fallback: try first part before comma (e.g., "Amsterdam, Netherlands" → "Amsterdam")
      if (city.contains(',')) {
        weather = await _fetchCity(city.split(',').first.trim());
        if (weather != null) return weather;
      }

      // Fallback: try first word only
      final firstWord = city.split(' ').first.trim();
      if (firstWord != city) {
        weather = await _fetchCity(firstWord);
      }
      return weather;
    } catch (_) {}
    return null;
  }

  static Future<WeatherData?> _fetchCity(String city) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?q=${Uri.encodeComponent(city)}'
        '&appid=$_apiKey'
        '&units=metric');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      return _parse(json.decode(response.body));
    }
    return null;
  }

  /// Fetch weather by coordinates
  static Future<WeatherData?> fetchByCoords(double lat, double lon) async {
    try {
      final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather'
          '?lat=$lat&lon=$lon'
          '&appid=$_apiKey'
          '&units=metric');

      final response = await http.get(url);
      if (response.statusCode == 200) {
        return _parse(json.decode(response.body));
      }
    } catch (_) {}
    return null;
  }

  static WeatherData? _parse(Map<String, dynamic> data) {
    try {
      final main = data['main'];
      final weather = (data['weather'] as List).first;
      final name = data['name'] as String?;
      return WeatherData(
        temperature: (main['temp'] as num).toDouble(),
        icon: weather['icon'] as String,
        description: weather['description'] as String,
        cityName: name,
      );
    } catch (_) {
      return null;
    }
  }
}
