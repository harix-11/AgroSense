import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/error/failures.dart';
import '../../core/error/exceptions.dart';
import '../local/database/app_database.dart' as db;
import '../../core/utils/logger.dart';

/// Repository for Task operations
/// Implements offline-first pattern with local database
class TaskRepository {
  final db.AppDatabase _database;

  TaskRepository(this._database);

  /// Get tasks by user ID
  /// Returns stream for real-time updates
  Stream<Either<Failure, List<db.Task>>> watchTasksByUserId(String userId) {
    try {
      return _database.watchTasksByUserId(userId).map((tasks) => Right(tasks));
    } catch (e) {
      AppLogger.error('Error watching tasks', e);
      return Stream.value(Left(DatabaseFailure(message: e.toString())));
    }
  }

  /// Get tasks for a specific date
  Future<Either<Failure, List<db.Task>>> getTasksByDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final tasks = await _database.getTasksByDate(userId, date);
      return Right(tasks);
    } on DatabaseException catch (e) {
      AppLogger.error('Error getting tasks by date', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error getting tasks', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Create new task
  /// Writes to local DB immediately, syncs to cloud later
  Future<Either<Failure, int>> createTask({
    required String userId,
    String? fieldId,
    required String title,
    String? description,
    required String taskType,
    required DateTime dueDate,
    int priority = 0,
  }) async {
    try {
      final taskId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();

      final task = db.TasksCompanion(
        id: drift.Value(taskId),
        userId: drift.Value(userId),
        fieldId: drift.Value(fieldId),
        title: drift.Value(title),
        description: drift.Value(description),
        taskType: drift.Value(taskType),
        dueDate: drift.Value(dueDate),
        priority: drift.Value(priority),
        isCompleted: const drift.Value(false),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false), // Mark for sync
        isDeleted: const drift.Value(false),
      );

      final result = await _database.insertTask(task);
      AppLogger.info('Task created locally: $taskId');
      
      return Right(result);
    } on DatabaseException catch (e) {
      AppLogger.error('Error creating task', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error creating task', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Update existing task
  Future<Either<Failure, bool>> updateTask({
    required String taskId,
    String? title,
    String? description,
    DateTime? dueDate,
    int? priority,
  }) async {
    try {
      final task = db.TasksCompanion(
        id: drift.Value(taskId),
        title: title != null ? drift.Value(title) : const drift.Value.absent(),
        description: description != null 
            ? drift.Value(description) 
            : const drift.Value.absent(),
        dueDate: dueDate != null 
            ? drift.Value(dueDate) 
            : const drift.Value.absent(),
        priority: priority != null 
            ? drift.Value(priority) 
            : const drift.Value.absent(),
        updatedAt: drift.Value(DateTime.now()),
        isSynced: const drift.Value(false), // Mark for sync
      );

      final result = await _database.updateTask(task);
      AppLogger.info('Task updated locally: $taskId');
      
      return Right(result);
    } on DatabaseException catch (e) {
      AppLogger.error('Error updating task', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error updating task', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Mark task as completed
  Future<Either<Failure, int>> completeTask(String taskId) async {
    try {
      final result = await _database.completeTask(taskId);
      AppLogger.info('Task completed: $taskId');
      
      return Right(result);
    } on DatabaseException catch (e) {
      AppLogger.error('Error completing task', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error completing task', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Delete task (soft delete)
  Future<Either<Failure, int>> deleteTask(String taskId) async {
    try {
      // Soft delete by setting isDeleted flag
      final result = await _database.transaction(() async {
        return await _database.customUpdate(
          'UPDATE tasks SET is_deleted = 1, is_synced = 0, updated_at = ? WHERE id = ?',
          updates: {_database.tasks},
          variables: [drift.Variable.withDateTime(DateTime.now()), drift.Variable.withString(taskId)],
        );
      });
      
      AppLogger.info('Task deleted: $taskId');
      return Right(result);
    } on DatabaseException catch (e) {
      AppLogger.error('Error deleting task', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error deleting task', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Auto-generate tasks based on crop type
  Future<Either<Failure, List<int>>> generateCropTasks({
    required String userId,
    required String fieldId,
    required String cropType,
    required DateTime plantingDate,
  }) async {
    try {
      final tasks = _getTasksForCrop(cropType, plantingDate);
      final results = <int>[];

      for (final taskData in tasks) {
        final now = DateTime.now();
        final task = db.TasksCompanion(
          id: drift.Value(DateTime.now().millisecondsSinceEpoch.toString()),
          userId: drift.Value(userId),
          fieldId: drift.Value(fieldId),
          title: drift.Value(taskData['title'] as String),
          description: drift.Value(taskData['description'] as String),
          taskType: drift.Value(taskData['type'] as String),
          dueDate: drift.Value(taskData['dueDate'] as DateTime),
          priority: drift.Value(taskData['priority'] as int),
          isCompleted: const drift.Value(false),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          isSynced: const drift.Value(false),
          isDeleted: const drift.Value(false),
        );

        final result = await _database.insertTask(task);
        results.add(result);
      }

      AppLogger.info('Generated ${results.length} tasks for $cropType');
      return Right(results);
    } catch (e) {
      AppLogger.error('Error generating crop tasks', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Get predefined tasks for crop types
  List<Map<String, dynamic>> _getTasksForCrop(
    String cropType,
    DateTime plantingDate,
  ) {
    switch (cropType.toLowerCase()) {
      case 'rice':
        return [
          {
            'title': 'First Watering',
            'description': 'Water the field thoroughly',
            'type': 'watering',
            'dueDate': plantingDate.add(const Duration(days: 3)),
            'priority': 2,
          },
          {
            'title': 'Apply Basal Fertilizer',
            'description': 'Apply NPK fertilizer as per soil test',
            'type': 'fertilizing',
            'dueDate': plantingDate.add(const Duration(days: 7)),
            'priority': 2,
          },
          {
            'title': 'Weed Control',
            'description': 'Remove weeds manually or apply herbicide',
            'type': 'weeding',
            'dueDate': plantingDate.add(const Duration(days: 20)),
            'priority': 1,
          },
          {
            'title': 'Top Dressing Fertilizer',
            'description': 'Apply urea for nitrogen boost',
            'type': 'fertilizing',
            'dueDate': plantingDate.add(const Duration(days: 30)),
            'priority': 2,
          },
          {
            'title': 'Pest Inspection',
            'description': 'Check for pests and diseases',
            'type': 'inspection',
            'dueDate': plantingDate.add(const Duration(days: 45)),
            'priority': 1,
          },
          {
            'title': 'Drainage Management',
            'description': 'Ensure proper drainage before harvest',
            'type': 'maintenance',
            'dueDate': plantingDate.add(const Duration(days: 110)),
            'priority': 1,
          },
          {
            'title': 'Harvest',
            'description': 'Harvest rice when grains are golden',
            'type': 'harvesting',
            'dueDate': plantingDate.add(const Duration(days: 120)),
            'priority': 2,
          },
        ];
      
      case 'wheat':
        return [
          {
            'title': 'Irrigation',
            'description': 'First irrigation after sowing',
            'type': 'watering',
            'dueDate': plantingDate.add(const Duration(days: 20)),
            'priority': 2,
          },
          {
            'title': 'Apply Nitrogen',
            'description': 'Top dressing with nitrogen',
            'type': 'fertilizing',
            'dueDate': plantingDate.add(const Duration(days: 30)),
            'priority': 2,
          },
          {
            'title': 'Harvest',
            'description': 'Harvest when grains are mature',
            'type': 'harvesting',
            'dueDate': plantingDate.add(const Duration(days: 130)),
            'priority': 2,
          },
        ];
      
      default:
        // Generic tasks for other crops
        return [
          {
            'title': 'First Watering',
            'description': 'Initial watering after planting',
            'type': 'watering',
            'dueDate': plantingDate.add(const Duration(days: 3)),
            'priority': 2,
          },
          {
            'title': 'General Inspection',
            'description': 'Check crop health',
            'type': 'inspection',
            'dueDate': plantingDate.add(const Duration(days: 14)),
            'priority': 1,
          },
        ];
    }
  }
}
