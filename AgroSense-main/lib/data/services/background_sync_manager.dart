import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../local/database/app_database.dart';
import '../services/sync_service.dart';
import '../../core/utils/logger.dart';

/// Background Sync Manager using WorkManager
/// 
/// This class configures and manages background sync operations
/// that run periodically even when the app is closed.
/// 
class BackgroundSyncManager {
  static const String syncTaskName = 'agrosense_sync_task';
  static const String syncTaskTag = 'agrosense_background_sync';
  
  /// Initialize WorkManager and register periodic sync task
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to true for debugging
    );
    
    await registerPeriodicSync();
  }
  
  /// Register periodic background sync (every 30 minutes)
  static Future<void> registerPeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      syncTaskName,
      syncTaskName,
      frequency: const Duration(minutes: 30),
      constraints: Constraints(
        networkType: NetworkType.connected, // Only run when internet is available
        requiresBatteryNotLow: true,
        requiresCharging: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      tag: syncTaskTag,
    );
    
    AppLogger.info('Background sync registered successfully');
  }
  
  /// Force immediate sync (called manually by user)
  static Future<void> triggerImmediateSync() async {
    await Workmanager().registerOneOffTask(
      'immediate_sync',
      syncTaskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    
    AppLogger.info('Immediate sync triggered');
  }
  
  /// Cancel all background sync tasks
  static Future<void> cancelAllSync() async {
    await Workmanager().cancelByTag(syncTaskTag);
    AppLogger.info('All sync tasks cancelled');
  }
}

/// WorkManager callback dispatcher
/// This function runs in a separate isolate
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      AppLogger.info('Background sync task started: $task');
      
      // Initialize Firebase in background isolate
      await Firebase.initializeApp();
      
      // Initialize database
      final database = AppDatabase();
      
      // Initialize sync service
      final syncService = SyncService(
        localDb: database,
        firestore: FirebaseFirestore.instance,
        connectivity: Connectivity(),
      );
      
      // Get current user ID from shared preferences or secure storage
      // For now, we'll use a placeholder - implement proper user session management
      const userId = 'current_user_id'; // TODO: Get actual user ID
      
      // Perform sync
      final success = await syncService.performSync(userId);
      
      AppLogger.info('Background sync completed: ${success ? "Success" : "Failed"}');
      
      return Future.value(success);
    } catch (e, stackTrace) {
      AppLogger.error('Background sync task failed', e, stackTrace);
      return Future.value(false);
    }
  });
}
