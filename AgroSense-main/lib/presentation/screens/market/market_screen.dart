import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database/app_database.dart';
import '../../../providers/repository_providers.dart';

/// Market Prices Screen with Live Price Tracking
class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  List<MarketPrice> _prices = [];
  bool _isLoading = true;
  String _selectedCommodity = 'All';
  final List<String> _commodities = [
    'All',
    'Wheat',
    'Rice',
    'Maize',
    'Cotton',
    'Soybean',
    'Sugarcane',
  ];

  @override
  void initState() {
    super.initState();
    _loadMarketPrices();
  }

  Future<void> _loadMarketPrices() async {
    setState(() => _isLoading = true);
    try {
      final marketRepo = ref.read(marketRepositoryProvider);
      final prices = await marketRepo.getMarketPrices();
      setState(() {
        // Convert Map to MarketPrice objects
        _prices = prices.map((p) => MarketPrice(
          id: p['id'] ?? '',
          commodity: p['commodity'] ?? '',
          market: p['market'] ?? '',
          state: p['state'] ?? '',
          minPrice: (p['minPrice'] as num?)?.toDouble() ?? 0.0,
          maxPrice: (p['maxPrice'] as num?)?.toDouble() ?? 0.0,
          modalPrice: (p['modalPrice'] as num?)?.toDouble() ?? 0.0,
          priceDate: DateTime.tryParse(p['priceDate'] ?? '') ?? DateTime.now(),
          cachedAt: DateTime.tryParse(p['cachedAt'] ?? '') ?? DateTime.now(),
          isSynced: p['isSynced'] ?? false,
        ),).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading prices: $e')),
        );
      }
    }
  }

  Future<void> _refreshPrices() async {
    try {
      // Just reload prices - API always fetches fresh data
      await _loadMarketPrices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prices updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }

  List<MarketPrice> get _filteredPrices {
    if (_selectedCommodity == 'All') return _prices;
    return _prices.where((p) => p.commodity.toLowerCase() == _selectedCommodity.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Market Prices',
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.success,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPrices,
            tooltip: 'Refresh Prices',
          ),
        ],
      ),
      body: Column(
        children: [
          // Commodity Filter
          Container(
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _commodities.length,
              itemBuilder: (context, index) {
                final commodity = _commodities[index];
                final isSelected = commodity == _selectedCommodity;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: FilterChip(
                    label: Text(commodity),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCommodity = commodity);
                    },
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.success.withOpacity(0.2),
                    checkmarkColor: AppColors.success,
                    labelStyle: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected ? AppColors.success : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Price List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPrices.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _refreshPrices,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16.w),
                          itemCount: _filteredPrices.length,
                          itemBuilder: (context, index) {
                            final price = _filteredPrices[index];
                            return _buildPriceCard(price);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPriceAlert,
        backgroundColor: AppColors.success,
        icon: const Icon(Icons.notifications_active),
        label: const Text('Price Alerts'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 80.sp, color: AppColors.success.withOpacity(0.3)),
          SizedBox(height: 16.h),
          const Text(
            'No market data available',
            style: AppTextStyles.h3,
          ),
          SizedBox(height: 8.h),
          Text(
            'Pull down to refresh and fetch latest prices',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _refreshPrices,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(MarketPrice price) {
    final priceRange = price.maxPrice - price.minPrice;
    final percentDiff = priceRange > 0 ? (priceRange / price.minPrice * 100) : 0;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: () => _showPriceDetails(price),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          price.commodity,
                          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14.sp, color: AppColors.textSecondary),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                '${price.market}, ${price.state}',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '₹${price.modalPrice.toStringAsFixed(0)}',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPriceInfo('Min', price.minPrice),
                  _buildPriceInfo('Modal', price.modalPrice),
                  _buildPriceInfo('Max', price.maxPrice),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        percentDiff > 0 ? Icons.trending_up : Icons.trending_flat,
                        size: 16.sp,
                        color: percentDiff > 0 ? AppColors.success : AppColors.textSecondary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${percentDiff.toStringAsFixed(1)}% range',
                        style: AppTextStyles.caption.copyWith(
                          color: percentDiff > 0 ? AppColors.success : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatDate(price.priceDate),
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInfo(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showPriceDetails(MarketPrice price) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(price.commodity, style: AppTextStyles.h2),
              SizedBox(height: 8.h),
              Text(
                '${price.market}, ${price.state}',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              SizedBox(height: 24.h),
              _buildDetailRow('Modal Price', '₹${price.modalPrice.toStringAsFixed(2)}'),
              _buildDetailRow('Minimum Price', '₹${price.minPrice.toStringAsFixed(2)}'),
              _buildDetailRow('Maximum Price', '₹${price.maxPrice.toStringAsFixed(2)}'),
              _buildDetailRow('Price Date', _formatDate(price.priceDate)),
              _buildDetailRow('Last Updated', _formatDate(price.cachedAt)),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showPriceAlert();
                  },
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Set Price Alert'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showPriceAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Price Alerts'),
        content: const Text('Price alert functionality will notify you when commodity prices reach your target.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
