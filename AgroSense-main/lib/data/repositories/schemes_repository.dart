import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';
import '../../core/error/failures.dart';
import '../../core/error/exceptions.dart';
import '../local/database/app_database.dart' as db;
import '../../core/utils/logger.dart';

/// Repository for Government Schemes operations
/// Manages agricultural schemes with eligibility logic
class SchemesRepository {
  final db.AppDatabase _database;

  SchemesRepository({
    required db.AppDatabase database,
  }) : _database = database;

  /// Get all cached schemes
  Future<Either<Failure, List<db.Scheme>>> getAllSchemes(
      {String? language}) async {
    try {
      final schemes = await _database.getAllSchemes(language: language);

      // TODO: If cache is expired, fetch from Supabase
      // For now, return cached schemes or empty list
      if (schemes.isEmpty) {
        AppLogger.info(
            'No cached schemes. Please add sample schemes or sync from Supabase.');
      }

      return Right(schemes);
    } on DatabaseException catch (e) {
      AppLogger.error('Error getting schemes', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error getting schemes', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Get eligible schemes for user
  Future<Either<Failure, List<db.Scheme>>> getEligibleSchemes({
    required String userId,
    String? language,
  }) async {
    try {
      // Get user data to check eligibility
      final user = await _database.getUserById(userId);
      if (user == null) {
        return const Left(ValidationFailure(message: 'User not found'));
      }

      // Get user's fields for land area
      final fields = await _database.getFieldsByUserId(userId);
      final totalArea =
          fields.fold<double>(0, (sum, field) => sum + field.area);

      // Get all schemes
      final schemesResult = await getAllSchemes(language: language);

      return schemesResult.fold(
        (failure) => Left(failure),
        (schemes) {
          // Filter schemes by eligibility
          final eligibleSchemes = schemes.where((scheme) {
            return _checkEligibility(scheme, {
              'landArea': totalArea,
              'userId': userId,
              // Add more criteria as needed
            });
          }).toList();

          AppLogger.info('Found ${eligibleSchemes.length} eligible schemes');
          return Right(eligibleSchemes);
        },
      );
    } catch (e) {
      AppLogger.error('Error getting eligible schemes', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Search schemes by keyword
  Future<Either<Failure, List<db.Scheme>>> searchSchemes({
    required String query,
    String? language,
  }) async {
    try {
      final schemes = await _database.searchSchemes(query, language: language);
      return Right(schemes);
    } on DatabaseException catch (e) {
      AppLogger.error('Error searching schemes', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error searching schemes', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Get scheme by ID
  Future<Either<Failure, db.Scheme?>> getSchemeById(String schemeId) async {
    try {
      final scheme = await _database.getSchemeById(schemeId);
      return Right(scheme);
    } on DatabaseException catch (e) {
      AppLogger.error('Error getting scheme by ID', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error getting scheme', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Refresh schemes from cloud
  Future<Either<Failure, bool>> refreshSchemes({String? language}) async {
    try {
      // TODO: Implement Supabase sync
      AppLogger.info('Schemes refresh from Supabase not yet implemented');
      return const Right(false);
    } catch (e) {
      AppLogger.error('Error refreshing schemes', e);
      return Left(NetworkFailure(message: e.toString()));
    }
  }

  /// Check if scheme cache is expired (older than 7 days)
  bool _isCacheExpired(List<db.Scheme> schemes) {
    if (schemes.isEmpty) return true;

    final oldestCache =
        schemes.map((s) => s.cachedAt).reduce((a, b) => a.isBefore(b) ? a : b);

    final expiryDate = DateTime.now().subtract(const Duration(days: 7));
    return oldestCache.isBefore(expiryDate);
  }

  /// Check eligibility based on criteria
  bool _checkEligibility(db.Scheme scheme, Map<String, dynamic> userContext) {
    try {
      final criteria =
          jsonDecode(scheme.eligibilityCriteria) as Map<String, dynamic>;

      // Check minimum land area
      if (criteria['minLandArea'] != null) {
        final minArea = (criteria['minLandArea'] as num).toDouble();
        final userArea = (userContext['landArea'] as num?)?.toDouble() ?? 0;
        if (userArea < minArea) return false;
      }

      // Check maximum land area
      if (criteria['maxLandArea'] != null) {
        final maxArea = (criteria['maxLandArea'] as num).toDouble();
        final userArea = (userContext['landArea'] as num?)?.toDouble() ?? 0;
        if (userArea > maxArea) return false;
      }

      // Check required crop types
      if (criteria['cropTypes'] != null) {
        final requiredCrops =
            (criteria['cropTypes'] as List).map((e) => e.toString()).toList();
        final userCrops = userContext['cropTypes'] as List<String>? ?? [];
        if (!requiredCrops.any((crop) => userCrops.contains(crop))) {
          return false;
        }
      }

      // Check state/region
      if (criteria['states'] != null) {
        final allowedStates =
            (criteria['states'] as List).map((e) => e.toString()).toList();
        final userState = userContext['state'] as String?;
        if (userState != null && !allowedStates.contains(userState)) {
          return false;
        }
      }

      // Add more eligibility checks as needed

      return true;
    } catch (e) {
      AppLogger.error('Error checking eligibility', e);
      return false; // Default to not eligible if criteria parsing fails
    }
  }

  /// Parse eligibility criteria
  Map<String, dynamic> parseEligibilityCriteria(String criteriaJson) {
    try {
      return jsonDecode(criteriaJson) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error parsing eligibility criteria', e);
      return {};
    }
  }

  /// Format scheme benefits for display
  String formatBenefits(db.Scheme scheme) {
    return scheme.benefits
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => '• $line')
        .join('\n');
  }

  /// Add sample schemes to database (for testing/initial setup)
  Future<void> addSampleSchemes() async {
    try {
      final sampleSchemes = [
        {
          'id': 'pm_kisan',
          'title': 'PM-KISAN',
          'description':
              'Pradhan Mantri Kisan Samman Nidhi - Direct income support of ₹6,000 per year',
          'eligibilityCriteria': jsonEncode({
            'minLandArea': 0,
            'maxLandArea': 100,
            'states': ['All'],
          }),
          'benefits':
              'Financial assistance of ₹6,000 per year in three equal installments',
          'applyUrl': 'https://pmkisan.gov.in/',
          'language': 'en',
        },
        {
          'id': 'crop_insurance',
          'title': 'Pradhan Mantri Fasal Bima Yojana',
          'description':
              'Crop insurance scheme providing financial support in case of crop loss',
          'eligibilityCriteria': jsonEncode({
            'minLandArea': 0,
          }),
          'benefits':
              'Insurance coverage for crop loss due to natural calamities\nLow premium rates\nQuick claim settlement',
          'applyUrl': 'https://pmfby.gov.in/',
          'language': 'en',
        },
        {
          'id': 'soil_health',
          'title': 'Soil Health Card Scheme',
          'description': 'Free soil testing and nutrient recommendations',
          'eligibilityCriteria': jsonEncode({
            'minLandArea': 0,
          }),
          'benefits':
              'Free soil testing\nCustomized nutrient recommendations\nImproved crop productivity',
          'applyUrl': 'https://soilhealth.dac.gov.in/',
          'language': 'en',
        },
      ];

      final now = DateTime.now();
      for (final schemeData in sampleSchemes) {
        final scheme = db.SchemesCompanion(
          id: drift.Value(schemeData['id'] as String),
          title: drift.Value(schemeData['title'] as String),
          description: drift.Value(schemeData['description'] as String),
          eligibilityCriteria:
              drift.Value(schemeData['eligibilityCriteria'] as String),
          benefits: drift.Value(schemeData['benefits'] as String),
          applyUrl: drift.Value(schemeData['applyUrl']),
          language: drift.Value(schemeData['language'] as String),
          cachedAt: drift.Value(now),
        );

        await _database.insertScheme(scheme);
      }

      AppLogger.info('Sample schemes added');
    } catch (e) {
      AppLogger.error('Error adding sample schemes', e);
    }
  }
}
