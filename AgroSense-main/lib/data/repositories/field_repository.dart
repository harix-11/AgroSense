import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/error/failures.dart';
import '../../core/error/exceptions.dart';
import '../local/database/app_database.dart' as db;
import '../../core/utils/logger.dart';
import 'dart:convert';

/// Repository for Field (GIS) operations
/// Manages land parcels with polygon coordinates
class FieldRepository {
  final db.AppDatabase _database;

  FieldRepository({required db.AppDatabase database}) : _database = database;

  /// Watch all fields for a user (real-time stream)
  Stream<Either<Failure, List<db.Field>>> watchFieldsByUserId(String userId) {
    try {
      return _database
          .watchFieldsByUserId(userId)
          .map((fields) => Right(fields));
    } catch (e) {
      AppLogger.error('Error watching fields', e);
      return Stream.value(Left(DatabaseFailure(message: e.toString())));
    }
  }

  /// Get all fields for a user
  Future<Either<Failure, List<db.Field>>> getFieldsByUserId(
    String userId,
  ) async {
    try {
      final fields = await _database.getFieldsByUserId(userId);
      return Right(fields);
    } on DatabaseException catch (e) {
      AppLogger.error('Error getting fields', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error getting fields', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Get field by ID
  Future<Either<Failure, db.Field?>> getFieldById(String fieldId) async {
    try {
      final field = await _database.getFieldById(fieldId);
      return Right(field);
    } on DatabaseException catch (e) {
      AppLogger.error('Error getting field by ID', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error getting field', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Create new field with GIS coordinates
  Future<Either<Failure, int>> createField({
    required String userId,
    required String name,
    required List<Map<String, double>> coordinates, // List of {lat, lng}
    required double area,
    String? cropType,
    String? soilType,
  }) async {
    try {
      final fieldId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();

      // Validate coordinates (must have at least 3 points for polygon)
      if (coordinates.length < 3) {
        return const Left(
          ValidationFailure(
            message: 'Field must have at least 3 coordinate points',
          ),
        );
      }

      // Convert coordinates to JSON string
      final coordinatesJson = jsonEncode(coordinates);

      final field = db.FieldsCompanion(
        id: drift.Value(fieldId),
        userId: drift.Value(userId),
        name: drift.Value(name),
        coordinates: drift.Value(coordinatesJson),
        area: drift.Value(area),
        cropType: drift.Value(cropType),
        soilType: drift.Value(soilType),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
        isDeleted: const drift.Value(false),
      );

      final result = await _database.insertField(field);
      AppLogger.info('Field created locally: $fieldId');

      // TODO: Sync to Supabase PostgreSQL in background

      return Right(result);
    } on DatabaseException catch (e) {
      AppLogger.error('Error creating field', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error creating field', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Update field
  Future<Either<Failure, bool>> updateField({
    required String fieldId,
    String? name,
    List<Map<String, double>>? coordinates,
    double? area,
    String? cropType,
    String? soilType,
  }) async {
    try {
      final now = DateTime.now();
      String? coordinatesJson;

      if (coordinates != null) {
        if (coordinates.length < 3) {
          return const Left(
            ValidationFailure(
              message: 'Field must have at least 3 coordinate points',
            ),
          );
        }
        coordinatesJson = jsonEncode(coordinates);
      }

      final field = db.FieldsCompanion(
        id: drift.Value(fieldId),
        name: name != null ? drift.Value(name) : const drift.Value.absent(),
        coordinates: coordinatesJson != null
            ? drift.Value(coordinatesJson)
            : const drift.Value.absent(),
        area: area != null ? drift.Value(area) : const drift.Value.absent(),
        cropType: cropType != null
            ? drift.Value(cropType)
            : const drift.Value.absent(),
        soilType: soilType != null
            ? drift.Value(soilType)
            : const drift.Value.absent(),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
      );

      final result = await _database.updateField(field);
      AppLogger.info('Field updated locally: $fieldId');

      // TODO: Sync to Supabase PostgreSQL in background

      return Right(result);
    } on DatabaseException catch (e) {
      AppLogger.error('Error updating field', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error updating field', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Delete field (soft delete)
  Future<Either<Failure, bool>> deleteField(String fieldId) async {
    try {
      final result = await _database.deleteField(fieldId);
      AppLogger.info('Field deleted locally: $fieldId');

      // TODO: Sync to Supabase PostgreSQL in background

      return Right(result > 0);
    } on DatabaseException catch (e) {
      AppLogger.error('Error deleting field', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error deleting field', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Calculate total area for user's fields
  Future<Either<Failure, double>> getTotalArea(String userId) async {
    try {
      final fields = await _database.getFieldsByUserId(userId);
      final totalArea = fields.fold<double>(
        0,
        (sum, field) => sum + field.area,
      );
      return Right(totalArea);
    } catch (e) {
      AppLogger.error('Error calculating total area', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Parse coordinates from JSON string
  List<Map<String, double>> parseCoordinates(String coordinatesJson) {
    try {
      final List<dynamic> decoded = jsonDecode(coordinatesJson);
      return decoded
          .map(
            (coord) => {
              'lat': (coord['lat'] as num).toDouble(),
              'lng': (coord['lng'] as num).toDouble(),
            },
          )
          .toList();
    } catch (e) {
      AppLogger.error('Error parsing coordinates', e);
      return [];
    }
  }
}
