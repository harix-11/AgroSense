import 'package:agrosense/data/local/database/app_database.dart';
import 'package:agrosense/data/services/adaptive_decision_engine.dart';
import 'package:drift/drift.dart';

/// Daily Decision Repository
///
/// Manages adaptive daily recommendations:
/// - Generate today's decisions
/// - Track completion
/// - Provide decision history
class DailyDecisionRepository {
  final AppDatabase _database;
  final AdaptiveDecisionEngine _decisionEngine;

  DailyDecisionRepository(this._database, this._decisionEngine);

  /// Generate today's decision for an active field crop
  ///
  /// This is the main entry point for the adaptive planning algorithm
  Future<String?> generateTodaysDecision({
    required String fieldCropId,
    Map<String, dynamic>? weatherData,
  }) async {
    try {
      final decision = await _decisionEngine.generateTodaysDecision(
        fieldCropId: fieldCropId,
        weatherData: weatherData,
      );

      if (decision == null) {
        return null;
      }

      // Check if decision has content (empty companion means duplicate)
      if (decision.id.present) {
        await _database.insertDailyDecision(decision);
        return decision.id.value;
      }

      return null;
    } catch (e) {
      print('Error generating decision: $e');
      return null;
    }
  }

  /// Get today's decisions for a user
  Stream<List<DailyDecision>> watchTodaysDecisions(String userId) {
    return _database.watchDailyDecisionsByDate(userId, DateTime.now());
  }

  /// Get decisions for a specific date
  Stream<List<DailyDecision>> watchDecisionsByDate(
      String userId, DateTime date) {
    return _database.watchDailyDecisionsByDate(userId, date);
  }

  /// Get all decisions for a field crop
  Future<List<DailyDecision>> getFieldCropDecisions(String fieldCropId) async {
    return _database.getDailyDecisionsByFieldCrop(fieldCropId);
  }

  /// Complete a decision
  Future<bool> completeDecision({
    required String decisionId,
    String? notes,
  }) async {
    try {
      await _database.completeDailyDecision(decisionId, notes);
      return true;
    } catch (e) {
      print('Error completing decision: $e');
      return false;
    }
  }

  /// Mark decision as skipped/ignored
  Future<bool> skipDecision({
    required String decisionId,
    String? reason,
  }) async {
    try {
      await _database.updateDailyDecision(
        DailyDecisionsCompanion(
          id: Value(decisionId),
          completionNotes: Value('Skipped: ${reason ?? "No reason provided"}'),
          updatedAt: Value(DateTime.now()),
          isSynced: const Value(false),
        ),
      );
      return true;
    } catch (e) {
      print('Error skipping decision: $e');
      return false;
    }
  }

  /// Get decision by ID
  Future<DailyDecision?> getDecisionById(String decisionId) async {
    final decisions = await _database.getDailyDecisionsByFieldCrop('');
    return decisions.where((d) => d.id == decisionId).firstOrNull;
  }

  /// Get completion statistics
  Future<Map<String, dynamic>> getCompletionStats({
    required String userId,
    int days = 7,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      // This is a simplified version - in production, you'd query by date range
      final allDecisions = await _database.getDailyDecisionsByFieldCrop('');
      final userDecisions = allDecisions
          .where((d) => d.userId == userId && d.decisionDate.isAfter(startDate))
          .toList();

      final total = userDecisions.length;
      final completed = userDecisions.where((d) => d.isCompleted).length;
      final pending = total - completed;

      final byType = <String, int>{};
      for (final decision in userDecisions) {
        byType[decision.decisionType] =
            (byType[decision.decisionType] ?? 0) + 1;
      }

      return {
        'total': total,
        'completed': completed,
        'pending': pending,
        'completionRate': total > 0 ? completed / total : 0.0,
        'byType': byType,
      };
    } catch (e) {
      print('Error getting completion stats: $e');
      return {
        'total': 0,
        'completed': 0,
        'pending': 0,
        'completionRate': 0.0,
        'byType': <String, int>{},
      };
    }
  }

  /// Generate decisions for all active crops (daily background job)
  Future<List<String>> generateAllActiveDecisions({
    required String userId,
    Map<String, dynamic>? weatherData,
  }) async {
    try {
      final fieldCrops = await _database.getFieldCropsByUserId(userId);
      final activeFieldCrops = fieldCrops.where((fc) => fc.status == 'active');

      final generatedIds = <String>[];

      for (final fieldCrop in activeFieldCrops) {
        final decisionId = await generateTodaysDecision(
          fieldCropId: fieldCrop.id,
          weatherData: weatherData,
        );

        if (decisionId != null) {
          generatedIds.add(decisionId);
        }
      }

      return generatedIds;
    } catch (e) {
      print('Error generating all decisions: $e');
      return [];
    }
  }
}
