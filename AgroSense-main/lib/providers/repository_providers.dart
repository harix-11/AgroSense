import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

import '../data/local/database/app_database.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/field_repository.dart';
import '../data/repositories/task_repository.dart';
import '../data/repositories/weather_repository.dart';
import '../data/repositories/market_repository.dart';
import '../data/repositories/diary_repository.dart';
import '../data/repositories/community_repository.dart';
import '../data/repositories/ai_repository.dart';
import '../data/repositories/schemes_repository.dart';
import '../data/repositories/crop_catalog_repository.dart';
import '../data/repositories/field_crop_repository.dart';
import '../data/repositories/daily_decision_repository.dart';
import '../data/services/adaptive_decision_engine.dart';

// ==================== HTTP CLIENT PROVIDER ====================

/// Provides Dio instance for HTTP requests
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
});

// ==================== DATABASE PROVIDER ====================

/// Provides singleton instance of AppDatabase
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// ==================== SUPABASE PROVIDERS ====================

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// ==================== REPOSITORY PROVIDERS ====================

/// Auth Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    supabaseClient: ref.read(supabaseClientProvider),
    googleSignIn: ref.read(googleSignInProvider),
    secureStorage: ref.read(secureStorageProvider),
    database: ref.read(databaseProvider),
  );
});

/// Field Repository (GIS)
final fieldRepositoryProvider = Provider<FieldRepository>((ref) {
  return FieldRepository(database: ref.read(databaseProvider));
});

/// Task Repository
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.read(databaseProvider));
});

/// Weather Repository
final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepository(ref.read(dioProvider), ref.read(databaseProvider));
});

/// Market Repository
final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepository(ref.read(dioProvider), ref.read(databaseProvider));
});

/// Diary Repository
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepository(database: ref.read(databaseProvider));
});

/// Community Repository
final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(database: ref.read(databaseProvider));
});

/// AI Repository (Gemini)
final aiRepositoryProvider = Provider<AIRepository>((ref) {
  return AIRepository(
    database: ref.read(databaseProvider),
    // API key will be read from AppConstants
  );
});

/// Schemes Repository
final schemesRepositoryProvider = Provider<SchemesRepository>((ref) {
  return SchemesRepository(database: ref.read(databaseProvider));
});

// ==================== ADAPTIVE PLANNING PROVIDERS ====================

/// Adaptive Decision Engine
final adaptiveDecisionEngineProvider = Provider<AdaptiveDecisionEngine>((ref) {
  return AdaptiveDecisionEngine(ref.read(databaseProvider));
});

/// Crop Catalog Repository
final cropCatalogRepositoryProvider = Provider<CropCatalogRepository>((ref) {
  return CropCatalogRepository(ref.read(databaseProvider));
});

/// Field Crop Repository
final fieldCropRepositoryProvider = Provider<FieldCropRepository>((ref) {
  return FieldCropRepository(
    ref.read(databaseProvider),
    ref.read(adaptiveDecisionEngineProvider),
  );
});

/// Daily Decision Repository
final dailyDecisionRepositoryProvider = Provider<DailyDecisionRepository>((
  ref,
) {
  return DailyDecisionRepository(
    ref.read(databaseProvider),
    ref.read(adaptiveDecisionEngineProvider),
  );
});

// ==================== STATE PROVIDERS ====================

/// Current User ID Provider
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  return await authRepo.getCurrentUserId();
});

/// Is Logged In Provider
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  return await authRepo.isLoggedIn();
});

// ==================== DATA STREAM PROVIDERS ====================

/// Watch User Fields (Real-time)
final userFieldsProvider = StreamProvider.family<List<Field>, String>((
  ref,
  userId,
) {
  final fieldRepo = ref.read(fieldRepositoryProvider);
  return fieldRepo.watchFieldsByUserId(userId).asyncMap((either) {
    return either.fold(
      (failure) => throw Exception(failure.message),
      (fields) => fields,
    );
  });
});

/// Watch User Tasks (Real-time)
final userTasksProvider = StreamProvider.family<List<Task>, String>((
  ref,
  userId,
) {
  final taskRepo = ref.read(taskRepositoryProvider);
  return taskRepo.watchTasksByUserId(userId).asyncMap((either) {
    return either.fold(
      (failure) => throw Exception(failure.message),
      (tasks) => tasks,
    );
  });
});

/// Watch User Diary Entries (Real-time)
final userDiaryEntriesProvider =
    StreamProvider.family<List<DiaryEntry>, String>((ref, userId) {
      final diaryRepo = ref.read(diaryRepositoryProvider);
      return diaryRepo.watchDiaryEntriesByUserId(userId).asyncMap((either) {
        return either.fold(
          (failure) => throw Exception(failure.message),
          (entries) => entries,
        );
      });
    });

/// Watch Community Posts (Real-time)
final communityPostsProvider = StreamProvider<List<Post>>((ref) {
  final communityRepo = ref.read(communityRepositoryProvider);
  return communityRepo.watchPosts(limit: 20).asyncMap((either) {
    return either.fold(
      (failure) => throw Exception(failure.message),
      (posts) => posts,
    );
  });
});

/// Watch Market Prices (Real-time)
final marketPricesProvider = StreamProvider<List<MarketPrice>>((ref) {
  final database = ref.read(databaseProvider);
  return database.watchMarketPrices();
});

/// Watch Today's Decisions (Real-time) - ADAPTIVE PLANNING
final todaysDecisionsProvider =
    StreamProvider.family<List<DailyDecision>, String>((ref, userId) {
      final decisionRepo = ref.read(dailyDecisionRepositoryProvider);
      return decisionRepo.watchTodaysDecisions(userId);
    });

/// Watch User Field Crops (Real-time) - ADAPTIVE PLANNING
final userFieldCropsProvider = FutureProvider.family<List<FieldCrop>, String>((
  ref,
  userId,
) async {
  final fieldCropRepo = ref.read(fieldCropRepositoryProvider);
  return fieldCropRepo.getUserFieldCrops(userId);
});

// ==================== COMPUTED PROVIDERS ====================

/// Total Field Area for User
final totalFieldAreaProvider = FutureProvider.family<double, String>((
  ref,
  userId,
) async {
  final fieldRepo = ref.read(fieldRepositoryProvider);
  final result = await fieldRepo.getTotalArea(userId);
  return result.fold((failure) => 0.0, (area) => area);
});

/// Today's Tasks Count
final todayTasksCountProvider = FutureProvider.family<int, String>((
  ref,
  userId,
) async {
  final taskRepo = ref.read(taskRepositoryProvider);
  final today = DateTime.now();
  final result = await taskRepo.getTasksByDate(userId, today);
  return result.fold(
    (failure) => 0,
    (tasks) => tasks.where((t) => !t.isCompleted).length,
  );
});

/// Completed Tasks Count
final completedTasksCountProvider = FutureProvider.family<int, String>((
  ref,
  userId,
) async {
  final database = ref.read(databaseProvider);
  final tasks = await database.getTasksByDate(userId, DateTime.now());
  return tasks.where((t) => t.isCompleted).length;
});

// ==================== UTILITY PROVIDERS ====================

/// Logger for debugging
class RepositoryLogger {
  static void log(String message) {
    print('[Repository] $message');
  }

  static void error(String message, Object? error) {
    print('[Repository Error] $message: $error');
  }
}
