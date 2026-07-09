import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>> _forecast = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Mock data for now - replace with real weather repository
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _currentWeather = {
          'temperature': 28.5,
          'humidity': 65,
          'windSpeed': 12.5,
          'precipitation': 0,
          'description': 'Partly cloudy',
          'icon': '⛅',
        };

        _forecast = List.generate(7, (index) => {
          'date': DateTime.now().add(Duration(days: index)),
          'maxTemp': 30.0 + (index % 3),
          'minTemp': 22.0 + (index % 2),
          'precipitation': index % 3 == 0 ? 5.0 : 0.0,
          'description': index % 2 == 0 ? 'Sunny' : 'Partly cloudy',
          'icon': index % 2 == 0 ? '☀️' : '⛅',
        },);

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load weather data';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeatherData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadWeatherData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWeatherData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCurrentWeather(),
                        const SizedBox(height: 24),
                        _buildFarmingAdvice(),
                        const SizedBox(height: 24),
                        _buildForecast(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCurrentWeather() {
    if (_currentWeather == null) return const SizedBox();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              _currentWeather!['icon'],
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 16),
            Text(
              '${_currentWeather!['temperature'].toStringAsFixed(1)}°C',
              style: AppTextStyles.h1.copyWith(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              _currentWeather!['description'],
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherDetail(
                  Icons.water_drop,
                  'Humidity',
                  '${_currentWeather!['humidity']}%',
                ),
                _buildWeatherDetail(
                  Icons.air,
                  'Wind',
                  '${_currentWeather!['windSpeed']} km/h',
                ),
                _buildWeatherDetail(
                  Icons.umbrella,
                  'Rain',
                  '${_currentWeather!['precipitation']} mm',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFarmingAdvice() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: AppColors.secondary),
                SizedBox(width: 8),
                Text('Farming Advice', style: AppTextStyles.h3),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '• Good day for irrigation - temperature is moderate\n'
              '• Wind speed is ideal for pesticide spraying\n'
              '• No rain expected - safe for harvesting',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('7-Day Forecast', style: AppTextStyles.h3),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _forecast.length,
          itemBuilder: (context, index) {
            final day = _forecast[index];
            final date = day['date'] as DateTime;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Text(
                  day['icon'],
                  style: const TextStyle(fontSize: 32),
                ),
                title: Text(
                  _formatDate(date),
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(day['description']),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${day['maxTemp'].toStringAsFixed(0)}°',
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${day['minTemp'].toStringAsFixed(0)}°',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    if (date.day == DateTime.now().day) return 'Today';
    if (date.day == DateTime.now().add(const Duration(days: 1)).day) return 'Tomorrow';
    
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
