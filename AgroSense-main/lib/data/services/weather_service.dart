import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_constants.dart';
import '../local/database/app_database.dart';

class WeatherService {
  final Dio _dio = Dio();
  final AppDatabase _database;

  WeatherService(this._database);

  /// Get current weather and 7-day forecast
  Future<Map<String, dynamic>> getWeatherForecast({
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Get location if not provided
      if (latitude == null || longitude == null) {
        final position = await _getCurrentLocation();
        latitude = position.latitude;
        longitude = position.longitude;
      }

      // Check cache first
      final cached = await _getWeatherFromCache(latitude, longitude);
      if (cached != null) {
        return cached;
      }

      // Fetch from Open-Meteo API
      final response = await _dio.get(
        '${AppConstants.openMeteoBaseUrl}${ApiEndpoints.openMeteoForecast}',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum,weathercode,windspeed_10m_max',
          'current_weather': true,
          'timezone': 'auto',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _cacheWeather(latitude, longitude, data);
        return data;
      }

      throw Exception('Failed to fetch weather');
    } catch (e) {
      rethrow;
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<Map<String, dynamic>?> _getWeatherFromCache(
    double lat,
    double lon,
  ) async {
    final now = DateTime.now();
    final cached = await (_database.select(_database.weatherCache)
          ..where((tbl) =>
              tbl.latitude.equals(lat) &
              tbl.longitude.equals(lon) &
              tbl.expiresAt.isBiggerThan(Variable(now)),)
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.cachedAt, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();

    if (cached != null) {
      return jsonDecode(cached.weatherData) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> _cacheWeather(
    double lat,
    double lon,
    Map<String, dynamic> data,
  ) async {
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 1));

    await _database.into(_database.weatherCache).insert(
          WeatherCacheCompanion.insert(
            latitude: lat,
            longitude: lon,
            weatherData: jsonEncode(data),
            forecastDate: now,
            cachedAt: now,
            expiresAt: expiresAt,
          ),
        );
  }

  /// Get weather icon based on weather code
  String getWeatherIcon(int code) {
    if (code == 0) return '☀️'; // Clear
    if (code <= 3) return '🌤️'; // Partly cloudy
    if (code <= 48) return '🌫️'; // Fog
    if (code <= 67) return '🌧️'; // Rain
    if (code <= 77) return '🌨️'; // Snow
    if (code <= 99) return '⛈️'; // Thunderstorm
    return '🌤️';
  }

  /// Get AI-powered farming advice based on weather
  String getWeatherAdvice(Map<String, dynamic> weather) {
    final currentWeather = weather['current_weather'];
    final daily = weather['daily'];
    
    final temp = currentWeather['temperature'];
    final precipitation = daily['precipitation_sum'][0];
    
    if (precipitation > 10) {
      return '⚠️ Heavy rain expected. Avoid irrigation and field work.';
    } else if (precipitation > 0) {
      return '🌧️ Light rain expected. Good for transplanting.';
    } else if (temp > 35) {
      return '🌡️ High temperature. Increase irrigation frequency.';
    } else if (temp < 15) {
      return '❄️ Cold weather. Protect sensitive crops.';
    }
    
    return '✅ Good weather for farming activities.';
  }
}
