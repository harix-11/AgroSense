import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import '../local/database/app_database.dart';

class MarketPriceService {
  final Dio _dio = Dio();
  final AppDatabase _database;

  MarketPriceService(this._database);

  /// Fetch market prices from government API
  Future<List<MarketPrice>> getMarketPrices({
    String? commodity,
    String? state,
  }) async {
    try {
      // Check cache first (valid for 24 hours)
      final cached = await _getMarketPricesFromCache(commodity, state);
      if (cached.isNotEmpty) {
        return cached;
      }

      // Fetch from API (using India's government data portal)
      final response = await _dio.get(
        'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070',
        queryParameters: {
          'api-key': '579b464db66ec23bdd000001cdd3946e44ce4aad7209ff7b23ac571b',
          'format': 'json',
          'limit': 100,
          if (commodity != null) 'filters[commodity]': commodity,
          if (state != null) 'filters[state]': state,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final records = data['records'] as List;
        
        final prices = <MarketPrice>[];
        for (final record in records) {
          final price = await _createMarketPriceEntry(record);
          prices.add(price);
        }

        return prices;
      }

      throw Exception('Failed to fetch market prices');
    } catch (e) {
      // Return cached data if API fails
      return await _getMarketPricesFromCache(commodity, state);
    }
  }

  Future<List<MarketPrice>> _getMarketPricesFromCache(
    String? commodity,
    String? state,
  ) async {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 24));

    var query = _database.select(_database.marketPrices)
      ..where((tbl) => tbl.cachedAt.isBiggerOrEqualValue(cutoff))
      ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.priceDate)]);

    final prices = await query.get();
    return prices;
  }

  Future<MarketPrice> _createMarketPriceEntry(Map<String, dynamic> record) async {
    final id = '${record['commodity']}_${record['market']}_${DateTime.now().millisecondsSinceEpoch}';
    
    final companion = MarketPricesCompanion.insert(
      id: id,
      commodity: record['commodity'] ?? 'Unknown',
      market: record['market'] ?? 'Unknown',
      state: record['state'] ?? 'Unknown',
      minPrice: double.tryParse(record['min_price']?.toString() ?? '0') ?? 0,
      maxPrice: double.tryParse(record['max_price']?.toString() ?? '0') ?? 0,
      modalPrice: double.tryParse(record['modal_price']?.toString() ?? '0') ?? 0,
      priceDate: DateTime.tryParse(record['arrival_date'] ?? '') ?? DateTime.now(),
      cachedAt: DateTime.now(),
    );

    await _database.into(_database.marketPrices).insert(
          companion,
          mode: drift.InsertMode.insertOrReplace,
        );

    return (await (_database.select(_database.marketPrices)
              ..where((tbl) => tbl.id.equals(id)))
            .getSingle());
  }

  /// Get trending commodities
  Future<List<String>> getTrendingCommodities() async {
    final prices = await (_database.select(_database.marketPrices)
          ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.cachedAt)])
          ..limit(100))
        .get();

    final commodities = prices.map((p) => p.commodity).toSet().toList();
    return commodities.take(10).toList();
  }

  /// Calculate price trends
  Map<String, dynamic> calculateTrend(List<MarketPrice> prices) {
    if (prices.length < 2) {
      return {'trend': 'stable', 'change': 0.0};
    }

    final latest = prices.first.modalPrice;
    final previous = prices[1].modalPrice;
    final change = ((latest - previous) / previous * 100);

    String trend;
    if (change > 5) {
      trend = 'up';
    } else if (change < -5) {
      trend = 'down';
    } else {
      trend = 'stable';
    }

    return {'trend': trend, 'change': change};
  }
}
