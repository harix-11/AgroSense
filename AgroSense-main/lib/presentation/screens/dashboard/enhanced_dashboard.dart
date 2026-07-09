import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

// Comprehensive Real-time Dashboard Implementation
class EnhancedDashboardScreen extends ConsumerStatefulWidget {
  const EnhancedDashboardScreen({super.key});

  @override
  ConsumerState<EnhancedDashboardScreen> createState() => _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState extends ConsumerState<EnhancedDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgroSense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
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
        return const HomeTab();
      case 1:
        return const FieldsTab();
      case 2:
        return const CommunityTab();
      case 3:
        return const ProfileTab();
      default:
        return const HomeTab();
    }
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.landscape), label: 'Fields'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}

// ==================== HOME TAB ====================
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const FarmOverviewCard(),
            const WeatherCard(),
            const TodayTasksCard(),
            const QuickActionsGrid(),
            const UpcomingTasksCard(),
            SizedBox(height: 80.h),
          ],
        ),
      ),
    );
  }
}

// Farm Overview Card
class FarmOverviewCard extends StatelessWidget {
  const FarmOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Farm Overview',
            style: AppTextStyles.h2.copyWith(color: Colors.white),
          ),
          SizedBox(height: 16.h),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _OverviewItem('Total Area', '10.5 acres', Icons.landscape),
              _OverviewItem('Active Fields', '5', Icons.grid_on),
              _OverviewItem('Tasks', '12', Icons.task),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _OverviewItem(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32.sp),
        SizedBox(height: 8.h),
        Text(value, style: AppTextStyles.h2.copyWith(color: Colors.white)),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
      ],
    );
  }
}

// Weather Card
class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, Routes.weather),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Weather', style: AppTextStyles.h3),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Text('28°C', style: AppTextStyles.h1.copyWith(
                            fontSize: 48.sp,
                            fontWeight: FontWeight.bold,
                          ),),
                          SizedBox(width: 16.w),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Partly Cloudy', style: AppTextStyles.bodyLarge),
                              Text('Humidity: 65%', style: AppTextStyles.bodyMedium),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text('🌤️', style: TextStyle(fontSize: 64.sp)),
                ],
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20.sp),
                    SizedBox(width: 8.w),
                    const Expanded(
                      child: Text(
                        '✅ Good weather for farming activities',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Today's Tasks Card
class TodayTasksCard extends StatelessWidget {
  const TodayTasksCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = [
      {'title': 'Water Field A', 'time': '08:00 AM', 'done': false},
      {'title': 'Apply Fertilizer', 'time': '10:30 AM', 'done': false},
      {'title': 'Check Irrigation', 'time': '04:00 PM', 'done': true},
    ];

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Today\'s Tasks', style: AppTextStyles.h3),
                Chip(
                  label: const Text('3 Pending'),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ...tasks.map((task) => _TaskItem(
              title: task['title'] as String,
              time: task['time'] as String,
              isDone: task['done'] as bool,
            ),),
            SizedBox(height: 8.h),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Add New Task'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskItem extends StatefulWidget {
  final String title;
  final String time;
  final bool isDone;

  const _TaskItem({
    required this.title,
    required this.time,
    required this.isDone,
  });

  @override
  State<_TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<_TaskItem> {
  late bool _isDone;

  @override
  void initState() {
    super.initState();
    _isDone = widget.isDone;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: ListTile(
        leading: Checkbox(
          value: _isDone,
          onChanged: (value) => setState(() => _isDone = value ?? false),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            decoration: _isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(widget.time),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ),
    );
  }
}

// Quick Actions Grid
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {'icon': Icons.map, 'label': 'Map', 'route': '/map'},
      {'icon': Icons.cloud, 'label': 'Weather', 'route': Routes.weather},
      {'icon': Icons.psychology, 'label': 'Ask AI', 'route': Routes.aiAssistant},
      {'icon': Icons.store, 'label': 'Market', 'route': Routes.market},
      {'icon': Icons.book, 'label': 'Diary', 'route': Routes.diary},
      {'icon': Icons.card_giftcard, 'label': 'Schemes', 'route': Routes.schemes},
    ];

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: AppTextStyles.h3),
          SizedBox(height: 12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return _ActionCard(
                icon: action['icon'] as IconData,
                label: action['label'] as String,
                onTap: () {
                  final route = action['route'] as String;
                  if (route.isNotEmpty) {
                    Navigator.pushNamed(context, route);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32.sp, color: AppColors.primary),
            SizedBox(height: 8.h),
            Text(label, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// Upcoming Tasks Card
class UpcomingTasksCard extends StatelessWidget {
  const UpcomingTasksCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upcoming Tasks', style: AppTextStyles.h3),
            SizedBox(height: 12.h),
            const _UpcomingTaskItem('Harvest Field B', 'Tomorrow, 6:00 AM'),
            const _UpcomingTaskItem('Pest Inspection', 'Dec 3, 9:00 AM'),
            const _UpcomingTaskItem('Soil Testing', 'Dec 5, 10:00 AM'),
          ],
        ),
      ),
    );
  }
}

class _UpcomingTaskItem extends StatelessWidget {
  final String title;
  final String date;

  const _UpcomingTaskItem(this.title, this.date);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 20.sp, color: Colors.grey),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                Text(date, style: AppTextStyles.bodySmall.copyWith(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== FIELDS TAB ====================
class FieldsTab extends StatelessWidget {
  const FieldsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          const Text('My Fields', style: AppTextStyles.h2),
          SizedBox(height: 16.h),
          const _FieldCard('Field A - Wheat', '2.5 acres', 'Loamy Soil', Icons.grass),
          const _FieldCard('Field B - Rice', '3.0 acres', 'Clay Soil', Icons.rice_bowl),
          const _FieldCard('Field C - Vegetables', '1.5 acres', 'Sandy Soil', Icons.yard),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Add Field'),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String name;
  final String area;
  final String soil;
  final IconData icon;

  const _FieldCard(this.name, this.area, this.soil, this.icon);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(name),
        subtitle: Text('$area • $soil'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}

// ==================== COMMUNITY TAB ====================
class CommunityTab extends StatelessWidget {
  const CommunityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          const Text('Community', style: AppTextStyles.h2),
          SizedBox(height: 16.h),
          const _PostCard(
            'Rajesh Kumar',
            '2 hours ago',
            'Best time to harvest wheat?',
            'I have 5 acres of wheat ready. Weather forecast shows rain next week. Should I harvest now or wait?',
            likes: 24,
            comments: 12,
          ),
          const _PostCard(
            'Priya Sharma',
            '5 hours ago',
            'Organic pest control tips',
            'Successfully controlled aphids using neem oil spray. Sharing my experience...',
            likes: 45,
            comments: 18,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final String author;
  final String time;
  final String title;
  final String content;
  final int likes;
  final int comments;

  const _PostCard(
    this.author,
    this.time,
    this.title,
    this.content, {
    required this.likes,
    required this.comments,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(author[0]),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(author, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                      Text(time, style: AppTextStyles.bodySmall.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(title, style: AppTextStyles.h4),
            SizedBox(height: 8.h),
            Text(content),
            SizedBox(height: 12.h),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.thumb_up_outlined),
                  onPressed: () {},
                ),
                Text('$likes'),
                SizedBox(width: 24.w),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {},
                ),
                Text('$comments'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== PROFILE TAB ====================
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 50.r,
                child: Icon(Icons.person, size: 50.sp),
              ),
              SizedBox(height: 16.h),
              const Text('Farmer Name', style: AppTextStyles.h2),
              const Text('+91 98765 43210', style: AppTextStyles.bodyLarge),
            ],
          ),
        ),
        SizedBox(height: 32.h),
        _ProfileItem(Icons.person, 'Edit Profile', () {}),
        _ProfileItem(Icons.language, 'Language', () {}),
        _ProfileItem(Icons.notifications, 'Notifications', () {}),
        _ProfileItem(Icons.help, 'Help & Support', () {}),
        _ProfileItem(Icons.info, 'About', () {}),
        _ProfileItem(Icons.logout, 'Logout', () {}),
      ],
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileItem(this.icon, this.title, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
