import 'package:dartz/dartz.dart';

// Base Failure Class
abstract class Failure {
  final String message;
  final int? code;
  
  const Failure({required this.message, this.code});
}

// Network Failures
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection'});
}

class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Server error occurred', super.code});
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message = 'Request timeout'});
}

// Auth Failures
class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Authentication failed', super.code});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'Unauthorized access'});
}

// Database Failures
class DatabaseFailure extends Failure {
  const DatabaseFailure({super.message = 'Database error occurred'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache error occurred'});
}

// Validation Failures
class ValidationFailure extends Failure {
  const ValidationFailure({super.message = 'Invalid input'});
}

// Permission Failures
class PermissionFailure extends Failure {
  const PermissionFailure({super.message = 'Permission denied'});
}

// Storage Failures
class StorageFailure extends Failure {
  const StorageFailure({super.message = 'Storage operation failed', super.code});
}

// AI Failures
class AIFailure extends Failure {
  const AIFailure({super.message = 'AI service error', super.code});
}

// Generic Failure
class GenericFailure extends Failure {
  const GenericFailure({super.message = 'An error occurred', super.code});
}

// Type alias for Either result
typedef Result<T> = Either<Failure, T>;
