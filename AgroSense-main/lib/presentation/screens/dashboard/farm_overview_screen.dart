import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database/app_database.dart';
import '../../../providers/repository_providers.dart';

class FarmOverviewScreen extends ConsumerStatefulWidget {
  const FarmOverviewScreen({super.key});

  @override
  ConsumerState<FarmOverviewScreen> createState() => _FarmOverviewScreenState();
}

class _FarmOverviewScreenState extends ConsumerState<FarmOverviewScreen> {
  bool _isLoading = true;
  String? _error;
  
  int _totalFields = 0;
  double _totalArea = 0.0;
  int _pendingTasks = 0;
  int _completedThisWeek = 0;
  List<DiaryEntry> _recentDiaryEntries = [];
  List<MarketPrice> _topPrices = [];
  Map<String, dynamic>? _weatherData;
  Map<int, int> _taskCompletionData = {};
  double _totalExpense = 0.0;
  double _totalIncome = 0.0;

  @override
  void initState() {
    super.initState();
    _loadOverviewData();
  }

  Future<void> _loadOverviewData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final database = ref.read(databaseProvider);
      final authRepo = ref.read(authRepositoryProvider);
      
      final userId = await authRepo.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final fields = await database.getFieldsByUserId(userId);
      _totalFields = fields.length;
      _totalArea = fields.fold(0.0, (sum, field) => sum + field.area);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final allTasks = await database.watchTasksByUserId(userId).first;
      _pendingTasks = allTasks.where((t) => !t.isCompleted && !t.isDeleted).length;
      _completedThisWeek = allTasks.where((t) => 
        t.isCompleted && 
        t.completedAt != null &&
        t.completedAt!.isAfter(weekStart) && 
        t.completedAt!.isBefore(weekEnd.add(const Duration(days: 1))),
      ).length;

      _taskCompletionData = {};
      for (int i = 6; i >= 0; i--) {
        final day = today.subtract(Duration(days: i));
        final dayStart = DateTime(day.year, day.month, day.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        
        final completed = allTasks.where((t) => 
          t.isCompleted && 
          t.completedAt != null &&
          t.completedAt!.isAfter(dayStart) && 
          t.completedAt!.isBefore(dayEnd),
        ).length;
        
        _taskCompletionData[i] = completed;
      }

      final diaryEntries = await database.watchDiaryEntriesByUserId(userId).first;
      _recentDiaryEntries = diaryEntries.take(3).toList();

      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      
      _totalExpense = diaryEntries
          .where((e) => e.category == 'expense' && 
                       e.entryDate.isAfter(monthStart) && 
                       e.entryDate.isBefore(monthEnd.add(const Duration(days: 1))),)
          .fold(0.0, (sum, e) => sum + (e.amount ?? 0.0));
      
      _totalIncome = diaryEntries
          .where((e) => e.category == 'income' && 
                       e.entryDate.isAfter(monthStart) && 
                       e.entryDate.isBefore(monthEnd.add(const Duration(days: 1))),)
          .fold(0.0, (sum, e) => sum + (e.amount ?? 0.0));

      final marketRepo = ref.read(marketRepositoryProvider);
      final marketPricesData = await marketRepo.getMarketPrices();
      _topPrices = marketPricesData.take(3).map((p) => MarketPrice(
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

      try {
        final weatherRepo = ref.read(weatherRepositoryProvider);
        _weatherData = await weatherRepo.getWeatherData(11.0168, 76.9558);
      } catch (_) {
        _weatherData = null;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOverviewData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Text('Error: $_error', style: AppTextStyles.bodyMedium),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadOverviewData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOverviewData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickStats(),
            SizedBox(height: 16.h),
            if (_weatherData != null) _buildWeatherCard(),
            if (_weatherData != null) SizedBox(height: 16.h),
            _buildTaskCompletionChart(),
            SizedBox(height: 16.h),
            _buildExpenseIncomeCard(),
            SizedBox(height: 16.h),
            _buildRecentDiarySection(),
            SizedBox(height: 16.h),
            _buildMarketPricesSection(),
            SizedBox(height: 16.h),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Fields',
            _totalFields.toString(),
            '${_totalArea.toStringAsFixed(1)} acres',
            Icons.landscape,
            AppColors.primary,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            'Pending Tasks',
            _pendingTasks.toString(),
            'To complete',
            Icons.pending_actions,
            AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24.sp),
                const Spacer(),
                Text(value, style: AppTextStyles.h2.copyWith(color: color)),
              ],
            ),
            SizedBox(height: 8.h),
            Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            Text(subtitle, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    final temp = _weatherData!['temperature'];
    final desc = _weatherData!['description'] ?? '';
    final icon = _weatherData!['icon'] ?? '☀️';

    return Card(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.info.withOpacity(0.7), AppColors.info],
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Text(icon, style: TextStyle(fontSize: 48.sp)),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${temp?.toStringAsFixed(1)}°C',
                    style: AppTextStyles.h2.copyWith(color: Colors.white),
                  ),
                  Text(
                    desc,
                    style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                  ),
                  Text(
                    'Current Weather',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCompletionChart() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Task Completion (Last 7 Days)', style: AppTextStyles.h4),
            SizedBox(height: 16.h),
            SizedBox(
              height: 200.h,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (_taskCompletionData.values.isEmpty ? 10 : _taskCompletionData.values.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          final index = 6 - value.toInt();
                          return Text(
                            days[DateTime.now().subtract(Duration(days: index)).weekday - 1],
                            style: AppTextStyles.bodySmall,
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _taskCompletionData.entries.map((entry) {
                    return BarChartGroupData(
                      x: 6 - entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: AppColors.primary,
                          width: 16.w,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Center(
              child: Text(
                '$_completedThisWeek tasks completed this week',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseIncomeCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This Month', style: AppTextStyles.h4),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.trending_down, color: AppColors.error, size: 32.sp),
                      SizedBox(height: 8.h),
                      const Text('Expense', style: AppTextStyles.bodyMedium),
                      Text(
                        '₹${_totalExpense.toStringAsFixed(2)}',
                        style: AppTextStyles.h4.copyWith(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 60.h,
                  color: AppColors.divider,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.trending_up, color: AppColors.success, size: 32.sp),
                      SizedBox(height: 8.h),
                      const Text('Income', style: AppTextStyles.bodyMedium),
                      Text(
                        '₹${_totalIncome.toStringAsFixed(2)}',
                        style: AppTextStyles.h4.copyWith(color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Divider(height: 1.h),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Net: ', style: AppTextStyles.bodyMedium),
                Text(
                  '₹${(_totalIncome - _totalExpense).toStringAsFixed(2)}',
                  style: AppTextStyles.h4.copyWith(
                    color: (_totalIncome - _totalExpense) >= 0 ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDiarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Recent Diary Entries', style: AppTextStyles.h4),
            const Spacer(),
            TextButton(
              onPressed: () {
                // Navigate to diary screen
              },
              child: const Text('View All'),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        if (_recentDiaryEntries.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: const Center(
                child: Text('No diary entries', style: AppTextStyles.bodyMedium),
              ),
            ),
          )
        else
          ..._recentDiaryEntries.map((entry) => Card(
            margin: EdgeInsets.only(bottom: 8.h),
            child: ListTile(
              leading: Icon(_getCategoryIcon(entry.category), color: AppColors.primary),
              title: Text(entry.title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(DateFormat('MMM dd').format(entry.entryDate), style: AppTextStyles.bodySmall),
              trailing: entry.amount != null
                  ? Text(
                      '₹${entry.amount!.toStringAsFixed(0)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: entry.category == 'income' ? AppColors.success : AppColors.error,
                      ),
                    )
                  : null,
            ),
          ),),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'expense':
        return Icons.money_off;
      case 'income':
        return Icons.attach_money;
      case 'observation':
        return Icons.visibility;
      default:
        return Icons.note;
    }
  }

  Widget _buildMarketPricesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Market Prices', style: AppTextStyles.h4),
            const Spacer(),
            TextButton(
              onPressed: () {
                // Navigate to market prices screen
              },
              child: const Text('View All'),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        if (_topPrices.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: const Center(
                child: Text('No market data', style: AppTextStyles.bodyMedium),
              ),
            ),
          )
        else
          ..._topPrices.map((price) => Card(
            margin: EdgeInsets.only(bottom: 8.h),
            child: ListTile(
              leading: const Icon(Icons.store, color: AppColors.secondary),
              title: Text(price.commodity, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(price.market, style: AppTextStyles.bodySmall),
              trailing: Text(
                '₹${price.modalPrice.toStringAsFixed(0)}',
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: AppTextStyles.h4),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to add task
                },
                icon: const Icon(Icons.add_task),
                label: const Text('Add Task'),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to add diary
                },
                icon: const Icon(Icons.edit),
                label: const Text('Add Diary'),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // Navigate to weather
            },
            icon: const Icon(Icons.cloud),
            label: const Text('View Weather Forecast'),
          ),
        ),
      ],
    );
  }
}
