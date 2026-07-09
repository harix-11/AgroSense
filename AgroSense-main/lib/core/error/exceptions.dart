// Custom Exceptions
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  
  ServerException({required this.message, this.statusCode});
}

class NetworkException implements Exception {
  final String message;
  
  NetworkException({this.message = 'No internet connection'});
}

class DatabaseException implements Exception {
  final String message;
  
  DatabaseException({required this.message});
}

class CacheException implements Exception {
  final String message;
  
  CacheException({required this.message});
}

class AuthException implements Exception {
  final String message;
  final String? code;
  
  AuthException({required this.message, this.code});
}

class ValidationException implements Exception {
  final String message;
  
  ValidationException({required this.message});
}

class PermissionException implements Exception {
  final String message;
  
  PermissionException({required this.message});
}
