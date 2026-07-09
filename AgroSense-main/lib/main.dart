import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/language/language_selection_screen.dart';
import 'presentation/screens/auth/simple_login_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/dashboard/farm_overview_screen.dart';
import 'presentation/screens/weather/weather_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/fields/fields_screen.dart';
import 'presentation/screens/community/community_screen.dart';
import 'presentation/screens/ai/ai_assistant_screen.dart';
import 'presentation/screens/market/market_screen.dart';
import 'presentation/screens/diary/diary_screen.dart';
import 'presentation/screens/schemes/schemes_screen.dart';
import 'presentation/screens/tasks/today_tasks_screen.dart';
import 'presentation/screens/tasks/upcoming_tasks_screen.dart';
import 'presentation/screens/tasks/adaptive_tasks_screen.dart';
import 'data/local/database/app_database.dart';
import 'data/repositories/crop_catalog_repository.dart';
import 'providers/repository_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Initialize Easy Localization
  await EasyLocalization.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Database
  final database = AppDatabase();

  // Seed Crop Catalog (Adaptive Planning)
  try {
    final cropCatalog = CropCatalogRepository(database);
    await cropCatalog.seedCropCatalog();
    print('[AgroSense] Crop catalog initialized');
  } catch (e) {
    print('[AgroSense] Error seeding crop catalog: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        // Provide database instance
        databaseProvider.overrideWithValue(database),
      ],
      child: EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('ta'),
          Locale('hi'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const AgroSenseApp(),
      ),
    ),
  );
}

class AgroSenseApp extends ConsumerWidget {
  const AgroSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          initialRoute: Routes.splash,
          routes: {
            Routes.splash: (context) => const SplashScreen(),
            Routes.languageSelection: (context) =>
                const LanguageSelectionScreen(),
            Routes.simpleLogin: (context) => const SimpleLoginScreen(),
            Routes.dashboard: (context) => const DashboardScreen(),
            Routes.weather: (context) => const WeatherScreen(),
            Routes.settings: (context) => const SettingsScreen(),
            Routes.profile: (context) => const ProfileScreen(),
            Routes.fields: (context) => const FieldsScreen(),
            Routes.community: (context) => const CommunityScreen(),
            Routes.aiAssistant: (context) => const AiAssistantScreen(),
            Routes.market: (context) => const MarketScreen(),
            Routes.diary: (context) => const DiaryScreen(),
            Routes.schemes: (context) => const SchemesScreen(),
            Routes.todayTasks: (context) => const TodayTasksScreen(),
            Routes.upcomingTasks: (context) => const UpcomingTasksScreen(),
            Routes.adaptiveTasks: (context) => const AdaptiveTasksScreen(),
            Routes.farmOverview: (context) => const FarmOverviewScreen(),
          },
        );
      },
    );
  }
}
