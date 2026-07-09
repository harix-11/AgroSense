import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../local/database/app_database.dart';

class WeatherRepository {
  final Dio _dio;
  final AppDatabase _database;

  WeatherRepository(this._dio, this._database);

  /// Fetch weather data from Open-Meteo API
  Future<Map<String, dynamic>> getWeatherData(double latitude, double longitude) async {
    try {
      // Check cache first (valid for 1 hour)
      final cached = await _database.getWeatherCache(latitude, longitude);
      if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
        AppLogger.info('Weather data from cache');
        // Parse JSON from cached weatherData
        final Map<String, dynamic> weatherData = json.decode(cached.weatherData);
        return weatherData;
      }

      // Fetch from API
      final response = await _dio.get(
        '${AppConstants.openMeteoBaseUrl}/forecast',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'current': 'temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation,weather_code',
          'timezone': 'auto',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final current = data['current'];
        
        final weatherData = {
          'temperature': current['temperature_2m'],
          'humidity': current['relative_humidity_2m'],
          'windSpeed': current['wind_speed_10m'],
          'precipitation': current['precipitation'],
          'weatherCode': current['weather_code'],
          'description': _getWeatherDescription(current['weather_code']),
          'iconCode': _getWeatherIcon(current['weather_code']),
        };

        // Cache the data
        await _database.insertWeatherCache(
          WeatherCacheCompanion.insert(
            latitude: latitude,
            longitude: longitude,
            weatherData: json.encode(weatherData),
            forecastDate: DateTime.now(),
            cachedAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        );

        AppLogger.info('Weather data fetched from API');
        return weatherData;
      }

      throw Exception('Failed to fetch weather data');
    } catch (e) {
      AppLogger.error('Error fetching weather: $e');
      rethrow;
    }
  }

  /// Get 7-day forecast
  Future<List<Map<String, dynamic>>> getWeatherForecast(double latitude, double longitude) async {
    try {
      final response = await _dio.get(
        '${AppConstants.openMeteoBaseUrl}/forecast',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code',
          'timezone': 'auto',
          'forecast_days': 7,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['daily'];
        final List<Map<String, dynamic>> forecast = [];

        for (int i = 0; i < data['time'].length; i++) {
          forecast.add({
            'date': DateTime.parse(data['time'][i]),
            'maxTemp': data['temperature_2m_max'][i],
            'minTemp': data['temperature_2m_min'][i],
            'precipitation': data['precipitation_sum'][i],
            'weatherCode': data['weather_code'][i],
            'description': _getWeatherDescription(data['weather_code'][i]),
            'icon': _getWeatherIcon(data['weather_code'][i]),
          });
        }

        return forecast;
      }

      throw Exception('Failed to fetch forecast');
    } catch (e) {
      AppLogger.error('Error fetching forecast: $e');
      rethrow;
    }
  }

  String _getWeatherDescription(int code) {
    if (code == 0) return 'Clear sky';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 67) return 'Rainy';
    if (code <= 77) return 'Snowy';
    if (code <= 82) return 'Rain showers';
    if (code <= 86) return 'Snow showers';
    if (code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  String _getWeatherIcon(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 48) return '🌫️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '❄️';
    if (code <= 82) return '🌦️';
    if (code <= 86) return '🌨️';
    if (code <= 99) return '⛈️';
    return '🌤️';
  }
}
