import 'dart:convert';
import 'package:agrosense/data/local/database/app_database.dart';
import 'package:drift/drift.dart';

/// Adaptive Decision Engine
///
/// Implements daily crop planning algorithm that adjusts recommendations based on:
/// - Crop growth stages
/// - Weather conditions
/// - Historical task completion
/// - Farmer observations
///
/// Algorithm Flow (runs daily):
/// 1. Calculate days since planting
/// 2. Estimate current crop stage
/// 3. Evaluate risk using weather + observations
/// 4. Decide today's output (action/observation/no-action)
/// 5. Update future tasks
class AdaptiveDecisionEngine {
  final AppDatabase _database;

  AdaptiveDecisionEngine(this._database);

  /// Main entry point: Generate today's decision for a field crop
  ///
  /// INPUT:
  /// - fieldCropId: Active crop being evaluated
  /// - weatherData: Current + forecast weather (nullable for offline)
  ///
  /// PROCESS:
  /// 1. Load crop data and history
  /// 2. Calculate current stage
  /// 3. Evaluate risk
  /// 4. Generate decision
  ///
  /// OUTPUT:
  /// - DailyDecision record (action/observation/no-action)
  Future<DailyDecisionsCompanion?> generateTodaysDecision({
    required String fieldCropId,
    Map<String, dynamic>? weatherData,
  }) async {
    try {
      // Step 1: Load context
      final fieldCrop = await _database.getFieldCropById(fieldCropId);
      if (fieldCrop == null || fieldCrop.status != 'active') {
        return null;
      }

      final crop = await _database.getCropById(fieldCrop.cropId);
      if (crop == null) {
        return null;
      }

      final today = DateTime.now();
      final daysSincePlanting = today.difference(fieldCrop.plantingDate).inDays;

      // Step 2: Calculate current stage
      final stageInfo = _estimateCurrentStage(
        crop: crop,
        daysSincePlanting: daysSincePlanting,
        currentStage: fieldCrop.currentStage,
        currentStageDays: fieldCrop.currentStageDays,
        stageConfidence: fieldCrop.stageConfidence,
      );

      // Step 3: Load history
      final recentDecisions =
          await _database.getDailyDecisionsByFieldCrop(fieldCropId);
      final recentObservations =
          await _database.getObservationsByFieldCrop(fieldCropId);

      // Step 4: Evaluate risk
      final riskLevel = _evaluateRisk(
        weatherData: weatherData,
        stageInfo: stageInfo,
        recentDecisions: recentDecisions,
        recentObservations: recentObservations,
      );

      // Step 5: Generate decision
      final decision = _generateDecision(
        fieldCropId: fieldCropId,
        userId: fieldCrop.userId,
        crop: crop,
        stageInfo: stageInfo,
        riskLevel: riskLevel,
        weatherData: weatherData,
        daysSincePlanting: daysSincePlanting,
        recentDecisions: recentDecisions,
      );

      return decision;
    } catch (e) {
      print('Error in adaptive decision engine: $e');
      return null;
    }
  }

  /// Stage Estimation Algorithm
  ///
  /// Calculates which growth stage the crop is currently in based on:
  /// - Days since planting
  /// - Crop-specific stage durations
  /// - Current stage tracking
  /// - Confidence level
  Map<String, dynamic> _estimateCurrentStage({
    required Crop crop,
    required int daysSincePlanting,
    required String currentStage,
    required int currentStageDays,
    required double stageConfidence,
  }) {
    final stages = json.decode(crop.stagesJson) as List<dynamic>;

    int cumulativeDays = 0;
    String estimatedStage = currentStage;
    int stageDays = currentStageDays;
    double confidence = stageConfidence;

    // Find which stage we should be in based on days
    for (final stageData in stages) {
      final stage = stageData as Map<String, dynamic>;
      final minDays = stage['minDays'] as int;
      final maxDays = stage['maxDays'] as int;
      final avgDays = (minDays + maxDays) ~/ 2;

      if (daysSincePlanting >= cumulativeDays &&
          daysSincePlanting < cumulativeDays + avgDays) {
        estimatedStage = stage['name'] as String;
        stageDays = daysSincePlanting - cumulativeDays;

        // Confidence decreases if we're far from typical duration
        final daysIntoStage = daysSincePlanting - cumulativeDays;
        if (daysIntoStage > maxDays) {
          confidence = 0.3; // Low confidence if stage is taking too long
        } else if (daysIntoStage < minDays) {
          confidence = 0.4; // Low confidence if stage is too fast
        } else {
          confidence = 0.7; // Good confidence if in normal range
        }
        break;
      }

      cumulativeDays += avgDays;
    }

    return {
      'stage': estimatedStage,
      'stageDays': stageDays,
      'confidence': confidence,
      'daysSincePlanting': daysSincePlanting,
      'totalStages': stages.length,
    };
  }

  /// Risk Evaluation Algorithm
  ///
  /// Analyzes multiple factors to determine risk level:
  /// - Weather threats (extreme temp, heavy rain, drought)
  /// - Stage vulnerability
  /// - Historical patterns
  /// - Observation alerts
  String _evaluateRisk({
    Map<String, dynamic>? weatherData,
    required Map<String, dynamic> stageInfo,
    required List<DailyDecision> recentDecisions,
    required List<StageObservation> recentObservations,
  }) {
    int riskScore = 0;

    // Weather risk (if online)
    if (weatherData != null) {
      final temp = weatherData['temperature'] as double?;
      final rainfall = weatherData['rainfall'] as double?;
      final humidity = weatherData['humidity'] as double?;

      // Extreme temperature
      if (temp != null) {
        if (temp > 40 || temp < 10)
          riskScore += 2;
        else if (temp > 35 || temp < 15) riskScore += 1;
      }

      // Heavy rainfall
      if (rainfall != null && rainfall > 50) riskScore += 2;

      // Drought conditions
      if (humidity != null && humidity < 30) riskScore += 1;
    }

    // Stage vulnerability (certain stages need more attention)
    final stage = stageInfo['stage'] as String;
    if (stage == 'germination' ||
        stage == 'flowering' ||
        stage == 'grain_filling') {
      riskScore += 1; // Critical stages
    }

    // Historical patterns
    final incompleteDecisions = recentDecisions
        .where((d) => !d.isCompleted && d.decisionDate.isBefore(DateTime.now()))
        .length;
    if (incompleteDecisions > 3) riskScore += 1;

    // Observation alerts
    final lowConfidenceObs =
        recentObservations.where((o) => o.confidenceAdjustment < -0.2).length;
    if (lowConfidenceObs > 0) riskScore += 1;

    // Convert score to risk level
    if (riskScore >= 4) return 'high';
    if (riskScore >= 2) return 'medium';
    return 'low';
  }

  /// Decision Generation Algorithm
  ///
  /// Determines today's recommended action based on:
  /// - Current stage requirements
  /// - Risk level
  /// - Weather conditions
  /// - Recent actions
  DailyDecisionsCompanion _generateDecision({
    required String fieldCropId,
    required String userId,
    required Crop crop,
    required Map<String, dynamic> stageInfo,
    required String riskLevel,
    Map<String, dynamic>? weatherData,
    required int daysSincePlanting,
    required List<DailyDecision> recentDecisions,
  }) {
    final stage = stageInfo['stage'] as String;
    final confidence = stageInfo['confidence'] as double;
    final today = DateTime.now();

    // Check if we already have a decision for today
    final existingToday = recentDecisions
        .where((d) =>
            d.decisionDate.year == today.year &&
            d.decisionDate.month == today.month &&
            d.decisionDate.day == today.day)
        .firstOrNull;

    if (existingToday != null && !existingToday.isCompleted) {
      // Don't create duplicate decisions for same day
      return DailyDecisionsCompanion(); // Empty companion
    }

    // Stage-based action recommendations
    final stageAction = _getStageAction(
      stage: stage,
      crop: crop,
      daysSincePlanting: daysSincePlanting,
      weatherData: weatherData,
      riskLevel: riskLevel,
    );

    // Decide priority based on risk
    int priority = 0; // low
    if (riskLevel == 'high')
      priority = 2;
    else if (riskLevel == 'medium') priority = 1;

    // Build reasoning
    final reasoning = _buildReasoning(
      stage: stage,
      confidence: confidence,
      riskLevel: riskLevel,
      weatherData: weatherData,
      action: stageAction,
    );

    return DailyDecisionsCompanion.insert(
      id: 'dd_${DateTime.now().millisecondsSinceEpoch}',
      fieldCropId: fieldCropId,
      userId: userId,
      decisionDate: today,
      decisionType: stageAction['type'] as String,
      actionType: Value(stageAction['actionType'] as String?),
      title: stageAction['title'] as String,
      description: stageAction['description'] as String,
      reasoning: reasoning,
      priority: Value(priority),
      weatherContext:
          Value(weatherData != null ? json.encode(weatherData) : null),
      stageContext: Value(json.encode(stageInfo)),
      historyContext: Value(json.encode({
        'recentDecisionCount': recentDecisions.length,
        'lastWeekCompletion': _calculateCompletionRate(recentDecisions),
      })),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Get recommended action based on current stage
  Map<String, dynamic> _getStageAction({
    required String stage,
    required Crop crop,
    required int daysSincePlanting,
    Map<String, dynamic>? weatherData,
    required String riskLevel,
  }) {
    // Offline rule-based actions for South Indian crops
    switch (stage) {
      case 'land_preparation':
        return {
          'type': 'action',
          'actionType': 'soil_preparation',
          'title': 'Prepare Field for Sowing',
          'description':
              'Plow the field and apply organic manure. Ensure proper drainage channels.',
        };

      case 'sowing':
      case 'germination':
        if (weatherData != null) {
          final rainfall = weatherData['rainfall'] as double? ?? 0;
          if (rainfall > 30) {
            return {
              'type': 'observation',
              'actionType': null,
              'title': 'Monitor Seedling Health',
              'description':
                  'Heavy rain detected. Check for waterlogging and ensure drainage is working.',
            };
          }
        }
        return {
          'type': 'action',
          'actionType': 'watering',
          'title': 'Ensure Adequate Moisture',
          'description':
              'Keep soil moist for germination. Water if no recent rain (2-3 cm depth).',
        };

      case 'vegetative':
        if (daysSincePlanting % 7 == 0) {
          // Weekly check during vegetative
          return {
            'type': 'observation',
            'actionType': null,
            'title': 'Weekly Growth Check',
            'description':
                'Inspect plant height, leaf color, and pest presence. Take a photo for records.',
          };
        }

        if (daysSincePlanting % 15 == 0) {
          return {
            'type': 'action',
            'actionType': 'fertilizing',
            'title': 'Apply Nitrogen Fertilizer',
            'description':
                'Apply urea or organic nitrogen source for vegetative growth.',
          };
        }

        return {
          'type': 'no_action',
          'actionType': null,
          'title': 'Continue Regular Monitoring',
          'description': 'Crop is developing well. Check back tomorrow.',
        };

      case 'tillering':
      case 'stem_elongation':
        if (riskLevel == 'high') {
          return {
            'type': 'action',
            'actionType': 'pest_control',
            'title': 'Pest and Disease Check',
            'description':
                'Critical growth stage. Check for stem borers, leaf folders, or fungal issues.',
          };
        }
        return {
          'type': 'observation',
          'actionType': null,
          'title': 'Monitor Tiller/Stem Development',
          'description': 'Count tillers/stems and check for uniform growth.',
        };

      case 'flowering':
      case 'panicle_initiation':
        return {
          'type': 'action',
          'actionType': 'fertilizing',
          'title': 'Apply Potash and Micronutrients',
          'description':
              'Flowering stage requires potassium for grain development. Apply as per soil test.',
        };

      case 'grain_filling':
      case 'maturity':
        if (weatherData != null) {
          final temp = weatherData['temperature'] as double? ?? 30;
          if (temp > 38) {
            return {
              'type': 'action',
              'actionType': 'watering',
              'title': 'Protect from Heat Stress',
              'description':
                  'High temperature during grain filling. Ensure adequate irrigation.',
            };
          }
        }

        return {
          'type': 'observation',
          'actionType': null,
          'title': 'Monitor Grain Maturity',
          'description':
              'Check grain color and firmness. Harvest when 80% grains are mature.',
        };

      case 'harvest':
        return {
          'type': 'action',
          'actionType': 'harvesting',
          'title': 'Ready to Harvest',
          'description':
              'Crop has reached maturity. Plan harvest within the next 3-5 days.',
        };

      default:
        return {
          'type': 'observation',
          'actionType': null,
          'title': 'Daily Field Check',
          'description': 'Walk through the field and observe crop condition.',
        };
    }
  }

  /// Build human-readable reasoning for the decision
  String _buildReasoning({
    required String stage,
    required double confidence,
    required String riskLevel,
    Map<String, dynamic>? weatherData,
    required Map<String, dynamic> action,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
        '📊 Current Stage: ${stage.replaceAll('_', ' ').toUpperCase()}');
    buffer.writeln('🎯 Confidence: ${(confidence * 100).toStringAsFixed(0)}%');
    buffer.writeln('⚠️ Risk Level: ${riskLevel.toUpperCase()}');

    if (weatherData != null) {
      buffer.writeln('\n🌤️ Weather Context:');
      if (weatherData['temperature'] != null) {
        buffer.writeln('  • Temperature: ${weatherData['temperature']}°C');
      }
      if (weatherData['rainfall'] != null) {
        buffer.writeln('  • Rainfall: ${weatherData['rainfall']}mm');
      }
      if (weatherData['humidity'] != null) {
        buffer.writeln('  • Humidity: ${weatherData['humidity']}%');
      }
    } else {
      buffer.writeln('\n🔌 Offline Mode: Using rule-based recommendations');
    }

    buffer.writeln('\n💡 Why this recommendation:');
    if (stage == 'germination' || stage == 'flowering') {
      buffer.writeln('  • This is a critical stage requiring close attention');
    }
    if (riskLevel == 'high') {
      buffer.writeln('  • High risk detected - immediate action recommended');
    }

    return buffer.toString();
  }

  /// Calculate completion rate of recent decisions
  double _calculateCompletionRate(List<DailyDecision> decisions) {
    if (decisions.isEmpty) return 1.0;

    final lastWeek = DateTime.now().subtract(const Duration(days: 7));
    final recentDecisions =
        decisions.where((d) => d.decisionDate.isAfter(lastWeek)).toList();

    if (recentDecisions.isEmpty) return 1.0;

    final completed = recentDecisions.where((d) => d.isCompleted).length;
    return completed / recentDecisions.length;
  }

  /// Update field crop stage based on observations or time
  Future<void> updateFieldCropStage({
    required String fieldCropId,
    String? newStage,
    double? confidenceAdjustment,
  }) async {
    final fieldCrop = await _database.getFieldCropById(fieldCropId);
    if (fieldCrop == null) return;

    final crop = await _database.getCropById(fieldCrop.cropId);
    if (crop == null) return;

    final daysSincePlanting =
        DateTime.now().difference(fieldCrop.plantingDate).inDays;

    final stageInfo = _estimateCurrentStage(
      crop: crop,
      daysSincePlanting: daysSincePlanting,
      currentStage: newStage ?? fieldCrop.currentStage,
      currentStageDays: fieldCrop.currentStageDays,
      stageConfidence: fieldCrop.stageConfidence,
    );

    double newConfidence = stageInfo['confidence'] as double;
    if (confidenceAdjustment != null) {
      newConfidence = (newConfidence + confidenceAdjustment).clamp(0.0, 1.0);
    }

    await _database.updateFieldCrop(
      FieldCropsCompanion(
        id: Value(fieldCropId),
        currentStage: Value(stageInfo['stage'] as String),
        currentStageDays: Value(stageInfo['stageDays'] as int),
        stageConfidence: Value(newConfidence),
        lastStageUpdate: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }
}
