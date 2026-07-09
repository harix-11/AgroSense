// Core Constants
class AppConstants {
  // App Info
  static const String appName = 'AgroSense';
  static const String appVersion = '1.0.0';

  // Database
  static const String dbName = 'agrosense.db';
  static const int dbVersion = 1;

  // Supabase Tables (PostgreSQL)
  static const String usersCollection = 'users';
  static const String fieldsCollection = 'fields';
  static const String tasksCollection = 'tasks';
  static const String diaryCollection = 'diary';
  static const String postsCollection = 'posts';
  static const String schemesCollection = 'schemes';
  static const String pricesCollection = 'prices';

  // Sync
  static const Duration syncInterval = Duration(minutes: 30);
  static const int maxRetryAttempts = 3;

  // API Keys (Move to environment variables in production)
  static const String geminiApiKey = 'AIzaSyA14cixMyJbGXYn5mAcOoBySlq-BIRXtGI';
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1';

  // Supabase Configuration
  static const String supabaseUrl =
      'YOUR_SUPABASE_URL'; // Update with your Supabase URL
  static const String supabaseAnonKey =
      'YOUR_SUPABASE_ANON_KEY'; // Update with your anon key

  // Shared Preferences Keys
  static const String languageKey = 'selected_language';
  static const String themeKey = 'theme_mode';
  static const String firstLaunchKey = 'first_launch';
  static const String lastSyncKey = 'last_sync_timestamp';

  // Developer Mode
  static const bool isDeveloperMode = true; // Set to false in production

  // Secure Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';

  // Pagination
  static const int postsPerPage = 20;
  static const int tasksPerPage = 50;

  // Map
  static const double defaultZoom = 15.0;
  static const double maxZoom = 19.0;
  static const double minZoom = 5.0;
}

// API Endpoints
class ApiEndpoints {
  static const String openMeteoForecast = '/forecast';
  static const String enamApi =
      'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070';
}

// Route Names
class Routes {
  static const String splash = '/';
  static const String languageSelection = '/language';
  static const String auth = '/auth';
  static const String simpleLogin = '/auth/simple';
  static const String phoneAuth = '/auth/phone';
  static const String otpVerification = '/auth/otp';
  static const String mapSetup = '/map-setup';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String fields = '/fields';
  static const String weather = '/weather';
  static const String market = '/market';
  static const String cropManagement = '/crop-management';
  static const String taskDetails = '/task-details';
  static const String todayTasks = '/tasks/today';
  static const String upcomingTasks = '/tasks/upcoming';
  static const String adaptiveTasks = '/tasks/adaptive';
  static const String farmOverview = '/farm-overview';
  static const String diary = '/diary';
  static const String diaryEntry = '/diary/entry';
  static const String finance = '/finance';
  static const String community = '/community';
  static const String postDetails = '/post-details';
  static const String aiAssistant = '/ai-assistant';
  static const String schemes = '/schemes';
  static const String settings = '/settings';
}

// Asset Paths
class Assets {
  static const String imagesPath = 'assets/images/';
  static const String iconsPath = 'assets/icons/';
  static const String animationsPath = 'assets/animations/';

  // Images
  static const String logo = '${imagesPath}logo.png';
  static const String placeholder = '${imagesPath}placeholder.png';

  // Animations
  static const String splashAnimation = '${animationsPath}splash.json';
  static const String loadingAnimation = '${animationsPath}loading.json';
  static const String successAnimation = '${animationsPath}success.json';
  static const String errorAnimation = '${animationsPath}error.json';
}

// Error Messages
class ErrorMessages {
  static const String networkError = 'No internet connection';
  static const String serverError = 'Server error occurred';
  static const String unknownError = 'An unknown error occurred';
  static const String authError = 'Authentication failed';
  static const String permissionDenied = 'Permission denied';
  static const String invalidInput = 'Invalid input';
  static const String syncError = 'Sync failed';
}
