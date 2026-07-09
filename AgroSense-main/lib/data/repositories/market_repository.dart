import 'package:dio/dio.dart';
import '../../core/utils/logger.dart';
import '../local/database/app_database.dart';
import 'package:uuid/uuid.dart';

class MarketRepository {
  final Dio _dio;
  final AppDatabase _database;

  MarketRepository(this._dio, this._database);

  /// Fetch market prices (mock data for now - replace with real eNAM API)
  Future<List<Map<String, dynamic>>> getMarketPrices() async {
    try {
      // Check cache first (valid for 6 hours)
      final cached = await _database.getCachedMarketPrices();
      if (cached.isNotEmpty) {
        final firstItem = cached.first;
        if (firstItem.cachedAt.isAfter(DateTime.now().subtract(const Duration(hours: 6)))) {
          AppLogger.info('Market prices from cache');
          return cached.map((item) => {
            'commodity': item.commodity,
            'market': item.market,
            'state': item.state,
            'minPrice': item.minPrice,
            'maxPrice': item.maxPrice,
            'modalPrice': item.modalPrice,
            'date': item.priceDate,
          },).toList();
        }
      }

      // Mock data - replace with real API call
      final mockPrices = [
        {
          'commodity': 'Rice',
          'variety': 'Basmati',
          'market': 'Chennai',
          'minPrice': 2800.0,
          'maxPrice': 3200.0,
          'modalPrice': 3000.0,
          'date': DateTime.now(),
        },
        {
          'commodity': 'Wheat',
          'variety': 'Lokwan',
          'market': 'Delhi',
          'minPrice': 2100.0,
          'maxPrice': 2400.0,
          'modalPrice': 2250.0,
          'date': DateTime.now(),
        },
        {
          'commodity': 'Cotton',
          'variety': 'DCH-32',
          'market': 'Ahmedabad',
          'minPrice': 5500.0,
          'maxPrice': 6200.0,
          'modalPrice': 5850.0,
          'date': DateTime.now(),
        },
        {
          'commodity': 'Tomato',
          'variety': 'Hybrid',
          'market': 'Bangalore',
          'minPrice': 15.0,
          'maxPrice': 25.0,
          'modalPrice': 20.0,
          'date': DateTime.now(),
        },
      ];

      // Cache the data
      for (final price in mockPrices) {
        await _database.insertMarketPrice(
          MarketPricesCompanion.insert(
            id: const Uuid().v4(),
            commodity: price['commodity'] as String,
            market: price['market'] as String,
            state: 'Tamil Nadu', // Default state
            minPrice: price['minPrice'] as double,
            maxPrice: price['maxPrice'] as double,
            modalPrice: price['modalPrice'] as double,
            priceDate: price['date'] as DateTime,
            cachedAt: DateTime.now(),
          ),
        );
      }

      AppLogger.info('Market prices fetched');
      return mockPrices;
    } catch (e) {
      AppLogger.error('Error fetching market prices: $e');
      rethrow;
    }
  }

  /// Search commodities
  Future<List<Map<String, dynamic>>> searchCommodities(String query) async {
    try {
      final prices = await getMarketPrices();
      return prices.where((price) =>
        (price['commodity'] as String).toLowerCase().contains(query.toLowerCase()) ||
        (price['variety'] as String).toLowerCase().contains(query.toLowerCase()),
      ).toList();
    } catch (e) {
      AppLogger.error('Error searching commodities: $e');
      rethrow;
    }
  }
}
