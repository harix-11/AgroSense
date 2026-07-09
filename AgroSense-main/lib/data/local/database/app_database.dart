import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

part 'app_database.g.dart';

// ==================== TABLES ====================

// User Profile Table
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get name => text()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get language => text().withDefault(const Constant('en'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Fields (Land Parcels) Table
class Fields extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get coordinates => text()(); // JSON string of polygon coordinates
  RealColumn get area => real()(); // Area in acres
  TextColumn get cropType => text().nullable()();
  TextColumn get soilType => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Tasks Table
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get fieldId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get taskType =>
      text()(); // watering, fertilizing, harvesting, etc.
  DateTimeColumn get dueDate => dateTime()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get priority =>
      integer().withDefault(const Constant(0))(); // 0=low, 1=medium, 2=high
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Farm Diary Table
class DiaryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get fieldId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get imagePaths => text().nullable()(); // JSON array of image paths
  TextColumn get category => text()(); // observation, expense, income, note
  RealColumn get amount => real().nullable()(); // For expense/income
  DateTimeColumn get entryDate => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Weather Cache Table
class WeatherCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get weatherData => text()(); // JSON string
  DateTimeColumn get forecastDate => dateTime()();
  TextColumn get aiSummary => text().nullable()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
}

// Market Prices Table
class MarketPrices extends Table {
  TextColumn get id => text()();
  TextColumn get commodity => text()();
  TextColumn get market => text()();
  TextColumn get state => text()();
  RealColumn get minPrice => real()();
  RealColumn get maxPrice => real()();
  RealColumn get modalPrice => real()();
  DateTimeColumn get priceDate => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Community Posts Table
class Posts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get userName => text()();
  TextColumn get userPhotoUrl => text().nullable()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get imageUrls => text().nullable()(); // JSON array
  IntColumn get upvotes => integer().withDefault(const Constant(0))();
  IntColumn get commentsCount => integer().withDefault(const Constant(0))();
  TextColumn get tags => text().nullable()(); // JSON array
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Post Comments Table
class Comments extends Table {
  TextColumn get id => text()();
  TextColumn get postId => text()();
  TextColumn get userId => text()();
  TextColumn get userName => text()();
  TextColumn get userPhotoUrl => text().nullable()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Government Schemes Table
class Schemes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get eligibilityCriteria => text()(); // JSON object
  TextColumn get benefits => text()();
  TextColumn get applyUrl => text().nullable()();
  TextColumn get language => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Chat Messages Table (AI Assistant)
class ChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get message => text()();
  TextColumn get response => text()();
  BoolColumn get isUser => boolean()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Sync Queue Table (Track pending syncs)
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get table => text()();
  TextColumn get recordId => text()();
  TextColumn get operation => text()(); // insert, update, delete
  TextColumn get data => text().nullable()(); // JSON string of data
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text()(); // pending, processing, completed, failed
}

// ==================== ADAPTIVE PLANNING TABLES ====================

// Crops Catalog Table (Predefined crop database)
class Crops extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()(); // "Rice", "Sugarcane", "Cotton"
  TextColumn get scientificName => text().nullable()();
  TextColumn get category => text()(); // "Cereal", "Cash Crop", "Pulse"
  IntColumn get minDurationDays => integer()(); // Minimum crop duration
  IntColumn get maxDurationDays => integer()(); // Maximum crop duration
  TextColumn get stagesJson =>
      text()(); // JSON: [{name, minDays, maxDays, description}]
  TextColumn get region => text()(); // "South India", "All India"
  TextColumn get season => text()(); // "Kharif", "Rabi", "Zaid", "Year-round"
  TextColumn get waterRequirement =>
      text().nullable()(); // "High", "Medium", "Low"
  TextColumn get soilTypes =>
      text().nullable()(); // JSON array of suitable soils
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Field Crops Table (Active crop on a field - tracks lifecycle)
class FieldCrops extends Table {
  TextColumn get id => text()();
  TextColumn get fieldId => text()(); // Reference to Fields table
  TextColumn get cropId => text()(); // Reference to Crops table
  TextColumn get userId => text()();
  DateTimeColumn get plantingDate => dateTime()(); // When farmer planted
  DateTimeColumn get estimatedHarvestDate =>
      dateTime().nullable()(); // Calculated estimate
  TextColumn get currentStage =>
      text()(); // "germination", "vegetative", "flowering", etc.
  IntColumn get currentStageDays =>
      integer().withDefault(const Constant(0))(); // Days in current stage
  RealColumn get stageConfidence => real()
      .withDefault(const Constant(0.5))(); // 0-1, confidence in stage estimate
  DateTimeColumn get lastStageUpdate =>
      dateTime()(); // When stage was last evaluated
  TextColumn get status =>
      text()(); // "active", "harvested", "failed", "abandoned"
  TextColumn get notes => text().nullable()(); // Farmer's notes about this crop
  DateTimeColumn get actualHarvestDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Daily Decisions Table (Adaptive planning output)
class DailyDecisions extends Table {
  TextColumn get id => text()();
  TextColumn get fieldCropId =>
      text()(); // Which active crop this decision is for
  TextColumn get userId => text()();
  DateTimeColumn get decisionDate =>
      dateTime()(); // Date this decision applies to
  TextColumn get decisionType =>
      text()(); // "action", "observation", "no_action", "decision_window"
  TextColumn get actionType =>
      text().nullable()(); // "watering", "fertilizing", etc. (if action)
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get reasoning =>
      text()(); // Why this recommendation (algorithm explanation)
  IntColumn get priority =>
      integer().withDefault(const Constant(0))(); // 0=low, 1=medium, 2=high
  TextColumn get weatherContext =>
      text().nullable()(); // JSON snapshot of weather used
  TextColumn get stageContext =>
      text().nullable()(); // JSON snapshot of stage data used
  TextColumn get historyContext =>
      text().nullable()(); // JSON snapshot of history used
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get completionNotes =>
      text().nullable()(); // Farmer's notes on completion
  TextColumn get aiExplanation =>
      text().nullable()(); // Optional Gemini explanation (online only)
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Stage Observations Table (Farmer input to adjust stage confidence)
class StageObservations extends Table {
  TextColumn get id => text()();
  TextColumn get fieldCropId => text()();
  TextColumn get userId => text()();
  TextColumn get observedStage => text()(); // What stage farmer observed
  TextColumn get observationType => text()(); // "manual", "photo", "auto"
  TextColumn get indicators =>
      text().nullable()(); // JSON: what farmer saw (e.g., "flowers appeared")
  TextColumn get notes => text().nullable()();
  TextColumn get imagePaths => text().nullable()(); // JSON array of image paths
  RealColumn get confidenceAdjustment =>
      real()(); // -0.3 to +0.3 (how much to adjust stage confidence)
  DateTimeColumn get observedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ==================== DATABASE ====================

@DriftDatabase(
  tables: [
    Users,
    Fields,
    Tasks,
    DiaryEntries,
    WeatherCache,
    MarketPrices,
    Posts,
    Comments,
    Schemes,
    ChatMessages,
    SyncQueue,
    // Adaptive Planning Tables
    Crops,
    FieldCrops,
    DailyDecisions,
    StageObservations,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle database upgrades here
        if (from == 1 && to == 2) {
          // Migration from v1 to v2: Add adaptive planning tables
          await m.createTable(crops);
          await m.createTable(fieldCrops);
          await m.createTable(dailyDecisions);
          await m.createTable(stageObservations);
        }
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ==================== USER OPERATIONS ====================

  Future<User?> getUserById(String id) async {
    return (select(users)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertUser(UsersCompanion user) async {
    return into(users).insert(user, mode: InsertMode.replace);
  }

  Future<bool> updateUser(UsersCompanion user) async {
    return update(users).replace(user);
  }

  // ==================== FIELD OPERATIONS ====================

  Stream<List<Field>> watchFieldsByUserId(String userId) {
    return (select(fields)
          ..where(
              (tbl) => tbl.userId.equals(userId) & tbl.isDeleted.equals(false)))
        .watch();
  }

  Future<List<Field>> getFieldsByUserId(String userId) async {
    return (select(fields)
          ..where(
              (tbl) => tbl.userId.equals(userId) & tbl.isDeleted.equals(false)))
        .get();
  }

  Future<Field?> getFieldById(String fieldId) async {
    return (select(fields)..where((tbl) => tbl.id.equals(fieldId)))
        .getSingleOrNull();
  }

  Future<int> insertField(FieldsCompanion field) async {
    return into(fields).insert(field, mode: InsertMode.replace);
  }

  Future<bool> updateField(FieldsCompanion field) async {
    return update(fields).replace(field);
  }

  Future<int> deleteField(String id) async {
    return (update(fields)..where((tbl) => tbl.id.equals(id))).write(
        const FieldsCompanion(isDeleted: Value(true), isSynced: Value(false)));
  }

  Future<List<Field>> getUnsyncedFields(String userId) async {
    return (select(fields)
          ..where(
              (tbl) => tbl.userId.equals(userId) & tbl.isSynced.equals(false)))
        .get();
  }

  // ==================== TASK OPERATIONS ====================

  Stream<List<Task>> watchTasksByUserId(String userId,
      {DateTime? startDate, DateTime? endDate}) {
    var query = select(tasks)
      ..where((tbl) => tbl.userId.equals(userId) & tbl.isDeleted.equals(false));

    if (startDate != null && endDate != null) {
      query = query
        ..where((tbl) => tbl.dueDate.isBetweenValues(startDate, endDate));
    }

    return (query..orderBy([(tbl) => OrderingTerm(expression: tbl.dueDate)]))
        .watch();
  }

  Future<List<Task>> getTasksByDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(tasks)
          ..where(
            (tbl) =>
                tbl.userId.equals(userId) &
                tbl.isDeleted.equals(false) &
                tbl.dueDate.isBetweenValues(startOfDay, endOfDay),
          ))
        .get();
  }

  Future<int> insertTask(TasksCompanion task) async {
    return into(tasks).insert(task, mode: InsertMode.replace);
  }

  Future<bool> updateTask(TasksCompanion task) async {
    return update(tasks).replace(task);
  }

  Future<int> completeTask(String id) async {
    return (update(tasks)..where((tbl) => tbl.id.equals(id))).write(
      TasksCompanion(
        isCompleted: const Value(true),
        completedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  // ==================== DIARY OPERATIONS ====================

  Stream<List<DiaryEntry>> watchDiaryEntriesByUserId(String userId) {
    return (select(diaryEntries)
          ..where(
              (tbl) => tbl.userId.equals(userId) & tbl.isDeleted.equals(false))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.entryDate, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Future<List<DiaryEntry>> getDiaryEntriesByCategory(
      String userId, String category) async {
    return (select(diaryEntries)
          ..where(
            (tbl) =>
                tbl.userId.equals(userId) &
                tbl.category.equals(category) &
                tbl.isDeleted.equals(false),
          ))
        .get();
  }

  Future<List<DiaryEntry>> getDiaryEntriesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return (select(diaryEntries)
          ..where(
            (tbl) =>
                tbl.userId.equals(userId) &
                tbl.isDeleted.equals(false) &
                tbl.entryDate.isBetweenValues(startDate, endDate),
          )
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.entryDate, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<DiaryEntry?> getDiaryEntryById(String entryId) async {
    return (select(diaryEntries)..where((tbl) => tbl.id.equals(entryId)))
        .getSingleOrNull();
  }

  Future<int> insertDiaryEntry(DiaryEntriesCompanion entry) async {
    return into(diaryEntries).insert(entry, mode: InsertMode.replace);
  }

  Future<bool> updateDiaryEntry(DiaryEntriesCompanion entry) async {
    return update(diaryEntries).replace(entry);
  }

  Future<int> deleteDiaryEntry(String id) async {
    return (update(diaryEntries)..where((tbl) => tbl.id.equals(id))).write(
        const DiaryEntriesCompanion(
            isDeleted: Value(true), isSynced: Value(false)));
  }

  // ==================== WEATHER OPERATIONS ====================

  Future<WeatherCacheData?> getWeatherCache(double lat, double lon) async {
    final now = DateTime.now();

    return (select(weatherCache)
          ..where(
            (tbl) =>
                tbl.latitude.equals(lat) &
                tbl.longitude.equals(lon) &
                tbl.expiresAt.isBiggerThanValue(now),
          )
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.cachedAt, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> insertWeatherCache(WeatherCacheCompanion cache) async {
    return into(weatherCache).insert(cache, mode: InsertMode.replace);
  }

  // ==================== MARKET PRICES OPERATIONS ====================
  // ==================== ADAPTIVE PLANNING OPERATIONS ====================

  // Crops Catalog Operations
  Future<List<Crop>> getAllCrops() async {
    return (select(crops)..where((tbl) => tbl.isActive.equals(true))).get();
  }

  Future<List<Crop>> getCropsByCategory(String category) async {
    return (select(crops)
          ..where((tbl) =>
              tbl.category.equals(category) & tbl.isActive.equals(true)))
        .get();
  }

  Future<Crop?> getCropById(String cropId) async {
    return (select(crops)..where((tbl) => tbl.id.equals(cropId)))
        .getSingleOrNull();
  }

  Future<int> insertCrop(CropsCompanion crop) async {
    return into(crops).insert(crop, mode: InsertMode.replace);
  }

  // Field Crops Operations
  Future<FieldCrop?> getActiveFieldCrop(String fieldId) async {
    return (select(fieldCrops)
          ..where((tbl) =>
              tbl.fieldId.equals(fieldId) &
              tbl.status.equals('active') &
              tbl.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<List<FieldCrop>> getFieldCropsByUserId(String userId) async {
    return (select(fieldCrops)
          ..where(
              (tbl) => tbl.userId.equals(userId) & tbl.isDeleted.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.plantingDate, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<FieldCrop?> getFieldCropById(String fieldCropId) async {
    return (select(fieldCrops)..where((tbl) => tbl.id.equals(fieldCropId)))
        .getSingleOrNull();
  }

  Future<int> insertFieldCrop(FieldCropsCompanion fieldCrop) async {
    return into(fieldCrops).insert(fieldCrop, mode: InsertMode.replace);
  }

  Future<bool> updateFieldCrop(FieldCropsCompanion fieldCrop) async {
    return update(fieldCrops).replace(fieldCrop);
  }

  // Daily Decisions Operations
  Stream<List<DailyDecision>> watchDailyDecisionsByDate(
      String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(dailyDecisions)
          ..where((tbl) =>
              tbl.userId.equals(userId) &
              tbl.decisionDate.isBetweenValues(startOfDay, endOfDay) &
              tbl.isDeleted.equals(false))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.priority, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Future<List<DailyDecision>> getDailyDecisionsByFieldCrop(
      String fieldCropId) async {
    return (select(dailyDecisions)
          ..where((tbl) =>
              tbl.fieldCropId.equals(fieldCropId) & tbl.isDeleted.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.decisionDate, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<int> insertDailyDecision(DailyDecisionsCompanion decision) async {
    return into(dailyDecisions).insert(decision, mode: InsertMode.replace);
  }

  Future<bool> updateDailyDecision(DailyDecisionsCompanion decision) async {
    return update(dailyDecisions).replace(decision);
  }

  Future<int> completeDailyDecision(String decisionId, String? notes) async {
    return (update(dailyDecisions)..where((tbl) => tbl.id.equals(decisionId)))
        .write(
      DailyDecisionsCompanion(
        isCompleted: const Value(true),
        completedAt: Value(DateTime.now()),
        completionNotes: Value(notes),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  // Stage Observations Operations
  Future<List<StageObservation>> getObservationsByFieldCrop(
      String fieldCropId) async {
    return (select(stageObservations)
          ..where((tbl) =>
              tbl.fieldCropId.equals(fieldCropId) & tbl.isDeleted.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.observedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<int> insertStageObservation(
      StageObservationsCompanion observation) async {
    return into(stageObservations)
        .insert(observation, mode: InsertMode.replace);
  }

  Stream<List<MarketPrice>> watchMarketPrices() {
    return (select(marketPrices)
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.priceDate, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Future<List<MarketPrice>> getCachedMarketPrices() async {
    final cutoffDate = DateTime.now().subtract(const Duration(hours: 24));
    return (select(marketPrices)
          ..where((tbl) => tbl.cachedAt.isBiggerThanValue(cutoffDate))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.priceDate, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<int> insertMarketPrice(MarketPricesCompanion price) async {
    return into(marketPrices).insert(price, mode: InsertMode.replace);
  }

  // ==================== POSTS OPERATIONS ====================

  Stream<List<Post>> watchPosts({int limit = 20}) {
    return (select(posts)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)
          ])
          ..limit(limit))
        .watch();
  }

  Stream<List<Post>> watchAllPosts(int limit) {
    return watchPosts(limit: limit);
  }

  Future<List<Post>> getPostsByUserId(String userId) async {
    return (select(posts)
          ..where(
              (tbl) => tbl.userId.equals(userId) & tbl.isDeleted.equals(false))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<Post?> getPostById(String postId) async {
    return (select(posts)..where((tbl) => tbl.id.equals(postId)))
        .getSingleOrNull();
  }

  Future<int> insertPost(PostsCompanion post) async {
    return into(posts).insert(post, mode: InsertMode.replace);
  }

  Future<bool> updatePost(PostsCompanion post) async {
    return update(posts).replace(post);
  }

  Future<int> deletePost(String id) async {
    return (update(posts)..where((tbl) => tbl.id.equals(id))).write(
        const PostsCompanion(isDeleted: Value(true), isSynced: Value(false)));
  }

  Future<int> incrementPostUpvotes(String id) async {
    final post = await getPostById(id);
    if (post == null) return 0;

    return (update(posts)..where((tbl) => tbl.id.equals(id))).write(
      PostsCompanion(
        upvotes: Value(post.upvotes + 1),
        isSynced: const Value(false),
      ),
    );
  }

  Future<int> incrementPostCommentsCount(String id) async {
    final post = await getPostById(id);
    if (post == null) return 0;

    return (update(posts)..where((tbl) => tbl.id.equals(id))).write(
      PostsCompanion(
        commentsCount: Value(post.commentsCount + 1),
        isSynced: const Value(false),
      ),
    );
  }

  Future<int> decrementPostCommentsCount(String id) async {
    final post = await getPostById(id);
    if (post == null) return 0;

    return (update(posts)..where((tbl) => tbl.id.equals(id))).write(
      PostsCompanion(
        commentsCount: Value(post.commentsCount - 1),
        isSynced: const Value(false),
      ),
    );
  }

  Future<List<Post>> searchPosts(String query) async {
    return (select(posts)
          ..where(
            (tbl) =>
                (tbl.title.like('%$query%') | tbl.content.like('%$query%')) &
                tbl.isDeleted.equals(false),
          )
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // ==================== COMMENTS OPERATIONS ====================

  Stream<List<Comment>> watchCommentsByPostId(String postId) {
    return (select(comments)
          ..where(
              (tbl) => tbl.postId.equals(postId) & tbl.isDeleted.equals(false))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]))
        .watch();
  }

  Future<List<Comment>> getCommentsByPostId(String postId) async {
    return (select(comments)
          ..where(
              (tbl) => tbl.postId.equals(postId) & tbl.isDeleted.equals(false))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]))
        .get();
  }

  Future<Comment?> getCommentById(String commentId) async {
    return (select(comments)..where((tbl) => tbl.id.equals(commentId)))
        .getSingleOrNull();
  }

  Future<int> insertComment(CommentsCompanion comment) async {
    return into(comments).insert(comment, mode: InsertMode.replace);
  }

  Future<bool> updateComment(CommentsCompanion comment) async {
    return update(comments).replace(comment);
  }

  Future<int> deleteComment(String id) async {
    return (update(comments)..where((tbl) => tbl.id.equals(id))).write(
        const CommentsCompanion(
            isDeleted: Value(true), isSynced: Value(false)));
  }

  // ==================== SCHEMES OPERATIONS ====================

  Future<List<Scheme>> getSchemesByLanguage(String language) async {
    return (select(schemes)..where((tbl) => tbl.language.equals(language)))
        .get();
  }

  Future<List<Scheme>> getAllSchemes({String? language}) async {
    if (language != null) {
      return getSchemesByLanguage(language);
    }
    return select(schemes).get();
  }

  Future<Scheme?> getSchemeById(String schemeId) async {
    return (select(schemes)..where((tbl) => tbl.id.equals(schemeId)))
        .getSingleOrNull();
  }

  Future<List<Scheme>> searchSchemes(String query, {String? language}) async {
    var selectQuery = select(schemes)
      ..where(
        (tbl) => tbl.title.like('%$query%') | tbl.description.like('%$query%'),
      );

    if (language != null) {
      selectQuery = selectQuery..where((tbl) => tbl.language.equals(language));
    }

    return selectQuery.get();
  }

  Future<int> insertScheme(SchemesCompanion scheme) async {
    return into(schemes).insert(scheme, mode: InsertMode.replace);
  }

  // ==================== CHAT OPERATIONS ====================

  Stream<List<ChatMessage>> watchChatMessages(String userId) {
    return (select(chatMessages)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.timestamp)]))
        .watch();
  }

  Future<List<ChatMessage>> getChatMessagesByUserId(String userId) async {
    return (select(chatMessages)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.timestamp)]))
        .get();
  }

  Future<int> insertChatMessage(ChatMessagesCompanion message) async {
    return into(chatMessages).insert(message);
  }

  Future<int> deleteChatMessagesByUserId(String userId) async {
    return (delete(chatMessages)..where((tbl) => tbl.userId.equals(userId)))
        .go();
  }

  // ==================== SYNC QUEUE OPERATIONS ====================

  Future<List<SyncQueueData>> getPendingSyncItems() async {
    return (select(syncQueue)
          ..where((tbl) => tbl.status.equals('pending'))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]))
        .get();
  }

  Future<int> addToSyncQueue(SyncQueueCompanion item) async {
    return into(syncQueue).insert(item);
  }

  Future<int> updateSyncQueueStatus(int id, String status) async {
    return (update(syncQueue)..where((tbl) => tbl.id.equals(id)))
        .write(SyncQueueCompanion(status: Value(status)));
  }

  Future<int> deleteSyncQueueItem(int id) async {
    return (delete(syncQueue)..where((tbl) => tbl.id.equals(id))).go();
  }

  // ==================== BULK SYNC OPERATIONS ====================

  Future<List<Task>> getUnsyncedTasks() async {
    return (select(tasks)..where((tbl) => tbl.isSynced.equals(false))).get();
  }

  Future<List<DiaryEntry>> getUnsyncedDiaryEntries() async {
    return (select(diaryEntries)..where((tbl) => tbl.isSynced.equals(false)))
        .get();
  }

  Future<List<Post>> getUnsyncedPosts() async {
    return (select(posts)..where((tbl) => tbl.isSynced.equals(false))).get();
  }

  Future<void> markAsSynced(String tableName, String id) async {
    switch (tableName) {
      case 'fields':
        await (update(fields)..where((tbl) => tbl.id.equals(id)))
            .write(const FieldsCompanion(isSynced: Value(true)));
        break;
      case 'tasks':
        await (update(tasks)..where((tbl) => tbl.id.equals(id)))
            .write(const TasksCompanion(isSynced: Value(true)));
        break;
      case 'diary_entries':
        await (update(diaryEntries)..where((tbl) => tbl.id.equals(id)))
            .write(const DiaryEntriesCompanion(isSynced: Value(true)));
        break;
      case 'posts':
        await (update(posts)..where((tbl) => tbl.id.equals(id)))
            .write(const PostsCompanion(isSynced: Value(true)));
        break;
    }
  }
}

// Database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(path.join(dbFolder.path, 'agrosense.db'));
    return NativeDatabase(file);
  });
}
