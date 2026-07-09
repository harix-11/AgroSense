import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/local/database/app_database.dart';
import 'repository_providers.dart';

// ==================== TASK PROVIDERS ====================

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return TaskRepository(database);
});

final todayTasksProvider = StreamProvider<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTodayTasks();
});

final upcomingTasksProvider = StreamProvider<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchUpcomingTasks();
});

final allTasksProvider = StreamProvider<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchAllTasks();
});

// ==================== FIELD PROVIDERS ====================

final fieldRepositoryProvider = Provider<FieldRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return FieldRepository(database);
});

final allFieldsProvider = StreamProvider<List<Field>>((ref) {
  final repository = ref.watch(fieldRepositoryProvider);
  return repository.watchAllFields();
});

// ==================== DIARY PROVIDERS ====================

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return DiaryRepository(database);
});

final allDiaryEntriesProvider = StreamProvider<List<DiaryEntry>>((ref) {
  final repository = ref.watch(diaryRepositoryProvider);
  return repository.watchAllEntries();
});

// ==================== REPOSITORIES ====================

class TaskRepository {
  final AppDatabase _database;
  TaskRepository(this._database);

  Stream<List<Task>> watchTodayTasks() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (_database.select(_database.tasks)
          ..where((tbl) =>
              tbl.dueDate.isBiggerOrEqualValue(startOfDay) &
              tbl.dueDate.isSmallerThanValue(endOfDay) &
              tbl.isDeleted.equals(false),)
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.dueDate, mode: OrderingMode.asc)]))
        .watch();
  }

  Stream<List<Task>> watchUpcomingTasks() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final startOfTomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    return (_database.select(_database.tasks)
          ..where((tbl) =>
              tbl.dueDate.isBiggerOrEqualValue(startOfTomorrow) &
              tbl.isDeleted.equals(false),)
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.dueDate, mode: OrderingMode.asc)])
          ..limit(10))
        .watch();
  }

  Stream<List<Task>> watchAllTasks() {
    return (_database.select(_database.tasks)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<void> createTask(TasksCompanion task) async {
    await _database.into(_database.tasks).insert(task);
  }

  Future<void> updateTask(Task task) async {
    await _database.update(_database.tasks).replace(task);
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final task = await (_database.select(_database.tasks)
          ..where((tbl) => tbl.id.equals(taskId)))
        .getSingle();

    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: Value(!task.isCompleted ? DateTime.now() : null),
    );

    await _database.update(_database.tasks).replace(updated);
  }

  Future<void> deleteTask(String taskId) async {
    await (_database.update(_database.tasks)
          ..where((tbl) => tbl.id.equals(taskId)))
        .write(const TasksCompanion(isDeleted: Value(true)));
  }
}

class FieldRepository {
  final AppDatabase _database;
  FieldRepository(this._database);

  Stream<List<Field>> watchAllFields() {
    return (_database.select(_database.fields)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<void> createField(FieldsCompanion field) async {
    await _database.into(_database.fields).insert(field);
  }

  Future<void> updateField(Field field) async {
    await _database.update(_database.fields).replace(field);
  }

  Future<void> deleteField(String fieldId) async {
    await (_database.update(_database.fields)
          ..where((tbl) => tbl.id.equals(fieldId)))
        .write(const FieldsCompanion(isDeleted: Value(true)));
  }
}

class DiaryRepository {
  final AppDatabase _database;
  DiaryRepository(this._database);

  Stream<List<DiaryEntry>> watchAllEntries() {
    return (_database.select(_database.diaryEntries)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.entryDate, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<void> createEntry(DiaryEntriesCompanion entry) async {
    await _database.into(_database.diaryEntries).insert(entry);
  }

  Future<void> updateEntry(DiaryEntry entry) async {
    await _database.update(_database.diaryEntries).replace(entry);
  }

  Future<void> deleteEntry(String entryId) async {
    await (_database.update(_database.diaryEntries)
          ..where((tbl) => tbl.id.equals(entryId)))
        .write(const DiaryEntriesCompanion(isDeleted: Value(true)));
  }
}
