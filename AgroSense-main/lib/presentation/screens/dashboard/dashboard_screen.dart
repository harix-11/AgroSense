import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgroSense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.pushNamed(context, Routes.settings);
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildFieldsTab();
      case 2:
        return _buildCommunityTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  // ==================== HOME TAB ====================
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's Tasks Section
          _buildTodayTasks(),

          SizedBox(height: 16.h),

          // Quick Actions Grid
          _buildQuickActions(),

          SizedBox(height: 16.h),

          // Weather Widget
          _buildWeatherWidget(),

          SizedBox(height: 16.h),

          // Upcoming Tasks
          _buildUpcomingTasks(),

          SizedBox(height: 16.h),

          // Farm Statistics
          _buildFarmStatistics(),

          SizedBox(height: 80.h), // Bottom padding for nav bar
        ],
      ),
    );
  }

  Widget _buildTodayTasks() {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, Routes.todayTasks),
      child: Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today_outlined,
                    color: AppColors.textOnPrimary, size: 24.sp),
                SizedBox(width: 8.w),
                Text(
                  'Today\'s Tasks',
                  style:
                      AppTextStyles.h3.copyWith(color: AppColors.textOnPrimary),
                ),
                const Spacer(),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.textOnPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Tap to view',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'Manage your daily farm tasks',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textOnPrimary.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(String title, String time, bool isCompleted) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.circle_outlined,
            color: AppColors.textOnPrimary,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: AppTextStyles.h3,
          ),
          SizedBox(height: 12.h),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12.w,
            crossAxisSpacing: 12.w,
            childAspectRatio: 1,
            children: [
              _buildQuickActionCard(
                icon: Icons.auto_awesome,
                label: 'Smart Tasks',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pushNamed(context, Routes.adaptiveTasks);
                },
              ),
              _buildQuickActionCard(
                icon: Icons.cloud_outlined,
                label: 'Weather',
                color: AppColors.info,
                onTap: () {
                  Navigator.pushNamed(context, Routes.weather);
                },
              ),
              _buildQuickActionCard(
                icon: Icons.smart_toy_outlined,
                label: 'Ask AI',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pushNamed(context, Routes.aiAssistant);
                },
              ),
              _buildQuickActionCard(
                icon: Icons.trending_up,
                label: 'Market',
                color: AppColors.success,
                onTap: () {
                  Navigator.pushNamed(context, Routes.market);
                },
              ),
              _buildQuickActionCard(
                icon: Icons.book_outlined,
                label: 'Diary',
                color: AppColors.warning,
                onTap: () {
                  Navigator.pushNamed(context, Routes.diary);
                },
              ),
              _buildQuickActionCard(
                icon: Icons.account_balance_outlined,
                label: 'Schemes',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.pushNamed(context, Routes.schemes);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF50A7E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Weather',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Partly Cloudy',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textOnPrimary.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              Icon(Icons.wb_cloudy_outlined,
                  color: AppColors.textOnPrimary, size: 48.sp),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherDetail('28°C', 'Temp'),
              _buildWeatherDetail('65%', 'Humidity'),
              _buildWeatherDetail('12 km/h', 'Wind'),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.textOnPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    color: AppColors.textOnPrimary, size: 16.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Good conditions for watering crops today',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textOnPrimary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingTasks() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Upcoming Tasks', style: AppTextStyles.h3),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _buildUpcomingTaskCard(
              'Harvest Field B', 'Tomorrow', AppColors.success),
          _buildUpcomingTaskCard(
              'Soil Testing', 'In 3 days', AppColors.warning),
          _buildUpcomingTaskCard('Pest Control', 'In 5 days', AppColors.error),
        ],
      ),
    );
  }

  Widget _buildUpcomingTaskCard(String title, String time, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(time, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildFarmStatistics() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Farm Overview', style: AppTextStyles.h3),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total Area', '12.5 Acres',
                    Icons.landscape, AppColors.primary),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                    'Active Fields', '3', Icons.grid_on, AppColors.secondary),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('This Month', '₹45,000',
                    Icons.trending_up, AppColors.success),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard('Expenses', '₹18,500',
                    Icons.trending_down, AppColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.h),
          Text(value, style: AppTextStyles.h3.copyWith(color: color)),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  // ==================== FIELDS TAB ====================
  Widget _buildFieldsTab() {
    // Navigate to fields screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentIndex == 1) {
        Navigator.pushNamed(context, Routes.fields);
        setState(() => _currentIndex = 0); // Reset to home
      }
    });

    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // ==================== COMMUNITY TAB ====================
  Widget _buildCommunityTab() {
    // Navigate to community screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentIndex == 2) {
        Navigator.pushNamed(context, Routes.community);
        setState(() => _currentIndex = 0); // Reset to home
      }
    });

    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // ==================== PROFILE TAB ====================
  Widget _buildProfileTab() {
    // Navigate to full profile screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentIndex == 3) {
        Navigator.pushNamed(context, Routes.profile);
        setState(() => _currentIndex = 0); // Reset to home
      }
    });

    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // ==================== BOTTOM NAVIGATION ====================
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: 'Fields',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Community',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
