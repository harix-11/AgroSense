import 'dart:convert';
import 'package:agrosense/data/local/database/app_database.dart';
import 'package:agrosense/data/services/adaptive_decision_engine.dart';
import 'package:drift/drift.dart';

/// Field Crop Repository
///
/// Manages active crop lifecycle on fields:
/// - Start new crop
/// - Track growth stages
/// - Record observations
/// - Complete harvest
class FieldCropRepository {
  final AppDatabase _database;
  final AdaptiveDecisionEngine _decisionEngine;

  FieldCropRepository(this._database, this._decisionEngine);

  /// Start a new crop on a field
  Future<String?> startCrop({
    required String fieldId,
    required String cropId,
    required String userId,
    required DateTime plantingDate,
    String? notes,
  }) async {
    try {
      // Check if field already has active crop
      final existing = await _database.getActiveFieldCrop(fieldId);
      if (existing != null) {
        return null; // Field already has active crop
      }

      // Get crop data to calculate initial stage
      final crop = await _database.getCropById(cropId);
      if (crop == null) {
        return null;
      }

      // Calculate estimated harvest date
      final avgDuration =
          ((crop.minDurationDays + crop.maxDurationDays) / 2).round();
      final estimatedHarvest = plantingDate.add(Duration(days: avgDuration));

      // Get first stage from crop stages
      final stages = json.decode(crop.stagesJson) as List<dynamic>;
      final firstStage = stages.isNotEmpty
          ? (stages.first as Map<String, dynamic>)['name'] as String
          : 'germination';

      final fieldCropId = 'fc_${DateTime.now().millisecondsSinceEpoch}';

      await _database.insertFieldCrop(
        FieldCropsCompanion.insert(
          id: fieldCropId,
          fieldId: fieldId,
          cropId: cropId,
          userId: userId,
          plantingDate: plantingDate,
          estimatedHarvestDate: Value(estimatedHarvest),
          currentStage: firstStage,
          currentStageDays: const Value(0),
          stageConfidence: const Value(0.8), // High initial confidence
          lastStageUpdate: plantingDate,
          status: 'active',
          notes: Value(notes),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      return fieldCropId;
    } catch (e) {
      print('Error starting crop: $e');
      return null;
    }
  }

  /// Get active crop for a field
  Future<FieldCrop?> getActiveFieldCrop(String fieldId) async {
    return _database.getActiveFieldCrop(fieldId);
  }

  /// Get all field crops for a user
  Future<List<FieldCrop>> getUserFieldCrops(String userId) async {
    return _database.getFieldCropsByUserId(userId);
  }

  /// Get field crop by ID
  Future<FieldCrop?> getFieldCropById(String fieldCropId) async {
    return _database.getFieldCropById(fieldCropId);
  }

  /// Update crop stage (manual or automatic)
  Future<bool> updateStage({
    required String fieldCropId,
    required String newStage,
    double? confidenceAdjustment,
  }) async {
    try {
      await _decisionEngine.updateFieldCropStage(
        fieldCropId: fieldCropId,
        newStage: newStage,
        confidenceAdjustment: confidenceAdjustment,
      );
      return true;
    } catch (e) {
      print('Error updating stage: $e');
      return false;
    }
  }

  /// Record farmer observation about crop stage
  Future<bool> recordObservation({
    required String fieldCropId,
    required String observedStage,
    required String userId,
    String? notes,
    List<String>? imagePaths,
    List<String>? indicators,
    double confidenceAdjustment = 0.0,
  }) async {
    try {
      final observationId = 'obs_${DateTime.now().millisecondsSinceEpoch}';

      await _database.insertStageObservation(
        StageObservationsCompanion.insert(
          id: observationId,
          fieldCropId: fieldCropId,
          userId: userId,
          observedStage: observedStage,
          observationType:
              imagePaths != null && imagePaths.isNotEmpty ? 'photo' : 'manual',
          indicators:
              Value(indicators != null ? json.encode(indicators) : null),
          notes: Value(notes),
          imagePaths:
              Value(imagePaths != null ? json.encode(imagePaths) : null),
          confidenceAdjustment: confidenceAdjustment,
          observedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );

      // Update field crop stage confidence
      if (confidenceAdjustment != 0.0) {
        await updateStage(
          fieldCropId: fieldCropId,
          newStage: observedStage,
          confidenceAdjustment: confidenceAdjustment,
        );
      }

      return true;
    } catch (e) {
      print('Error recording observation: $e');
      return false;
    }
  }

  /// Get all observations for a field crop
  Future<List<StageObservation>> getObservations(String fieldCropId) async {
    return _database.getObservationsByFieldCrop(fieldCropId);
  }

  /// Complete harvest
  Future<bool> completeHarvest({
    required String fieldCropId,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      await _database.updateFieldCrop(
        FieldCropsCompanion(
          id: Value(fieldCropId),
          status: const Value('harvested'),
          actualHarvestDate: Value(now),
          notes: Value(notes),
          updatedAt: Value(now),
          isSynced: const Value(false),
        ),
      );
      return true;
    } catch (e) {
      print('Error completing harvest: $e');
      return false;
    }
  }

  /// Abandon crop (disease, natural disaster, etc.)
  Future<bool> abandonCrop({
    required String fieldCropId,
    String? reason,
  }) async {
    try {
      final now = DateTime.now();
      await _database.updateFieldCrop(
        FieldCropsCompanion(
          id: Value(fieldCropId),
          status: const Value('abandoned'),
          notes: Value(reason),
          updatedAt: Value(now),
          isSynced: const Value(false),
        ),
      );
      return true;
    } catch (e) {
      print('Error abandoning crop: $e');
      return false;
    }
  }

  /// Get crop statistics for a user
  Future<Map<String, dynamic>> getCropStatistics(String userId) async {
    final allCrops = await _database.getFieldCropsByUserId(userId);

    final active = allCrops.where((c) => c.status == 'active').length;
    final harvested = allCrops.where((c) => c.status == 'harvested').length;
    final abandoned = allCrops.where((c) => c.status == 'abandoned').length;

    // Calculate average crop duration for harvested crops
    final harvestedCrops = allCrops
        .where((c) => c.status == 'harvested' && c.actualHarvestDate != null);

    double avgDuration = 0;
    if (harvestedCrops.isNotEmpty) {
      final totalDays = harvestedCrops.fold<int>(0, (sum, crop) {
        return sum +
            crop.actualHarvestDate!.difference(crop.plantingDate).inDays;
      });
      avgDuration = totalDays / harvestedCrops.length;
    }

    return {
      'total': allCrops.length,
      'active': active,
      'harvested': harvested,
      'abandoned': abandoned,
      'averageDuration': avgDuration,
    };
  }
}
