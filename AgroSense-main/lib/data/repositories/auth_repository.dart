import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthException, User;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/error/failures.dart';
import '../../core/error/exceptions.dart';
import '../../core/utils/logger.dart';
import '../local/database/app_database.dart' as db;
import 'package:drift/drift.dart' as drift;

/// Repository for Authentication operations
/// Handles Supabase Auth and local user data
class AuthRepository {
  final SupabaseClient _supabaseClient;
  final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _secureStorage;
  final db.AppDatabase _database;

  AuthRepository({
    required SupabaseClient supabaseClient,
    required GoogleSignIn googleSignIn,
    required FlutterSecureStorage secureStorage,
    required db.AppDatabase database,
  })  : _supabaseClient = supabaseClient,
        _googleSignIn = googleSignIn,
        _secureStorage = secureStorage,
        _database = database;

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final token = await _secureStorage.read(key: 'user_token');
      // Support both Supabase auth and demo login
      return token != null && (token.isNotEmpty);
    } catch (e) {
      AppLogger.error('Error checking login status', e);
      return false;
    }
  }

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    try {
      // Check Supabase user first
      final user = _supabaseClient.auth.currentUser;
      if (user != null) {
        return user.id;
      }
      final userId = await _secureStorage.read(key: 'user_id');
      return userId;
    } catch (e) {
      AppLogger.error('Error getting current user ID', e);
      return null;
    }
  }

  /// Send OTP to phone number (Supabase implementation)
  Future<Either<Failure, String>> sendOTP(String phoneNumber) async {
    try {
      // TODO: Implement Supabase Phone OTP
      // await _supabaseClient.auth.signInWithOtp(
      //   phone: phoneNumber,
      // );

      AppLogger.info('OTP send not yet implemented with Supabase');
      return const Left(AuthFailure(
          message:
              'OTP authentication not yet implemented. Please use simple login.'));
    } on AuthException catch (e) {
      AppLogger.error('Auth error sending OTP', e);
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error sending OTP', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Verify OTP and sign in (Supabase implementation)
  Future<Either<Failure, String>> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      // TODO: Implement Supabase OTP verification
      // final response = await _supabaseClient.auth.verifyOTP(
      //   type: OtpType.sms,
      //   token: otp,
      //   phone: phoneNumber,
      // );

      AppLogger.info('OTP verification not yet implemented with Supabase');
      return const Left(AuthFailure(
          message:
              'OTP verification not yet implemented. Please use simple login.'));
    } catch (e) {
      AppLogger.error('Unexpected error verifying OTP', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Sign in with Google (Supabase implementation)
  Future<Either<Failure, String>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return const Left(AuthFailure(message: 'Google sign in cancelled'));
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // TODO: Implement Supabase Google OAuth
      // final response = await _supabaseClient.auth.signInWithIdToken(
      //   provider: OAuthProvider.google,
      //   idToken: googleAuth.idToken!,
      //   accessToken: googleAuth.accessToken,
      // );

      AppLogger.info('Google sign in not yet implemented with Supabase');
      return const Left(AuthFailure(
          message:
              'Google sign-in not yet implemented. Please use simple login.'));
    } catch (e) {
      AppLogger.error('Unexpected error with Google sign in', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Create or update user profile in local DB
  Future<void> _createOrUpdateUserProfile({
    required String userId,
    String? phoneNumber,
    String? email,
    String? name,
    String? photoUrl,
  }) async {
    final now = DateTime.now();

    // TODO: Sync to Supabase PostgreSQL
    // await _supabaseClient.from('users').upsert({
    //   'id': userId,
    //   'phone_number': phoneNumber,
    //   'email': email,
    //   'name': name ?? 'User',
    //   'photo_url': photoUrl,
    //   'language': 'en',
    //   'updated_at': now.toIso8601String(),
    // });

    // Save to local database
    final user = db.UsersCompanion(
      id: drift.Value(userId),
      phoneNumber: drift.Value(phoneNumber),
      email: drift.Value(email),
      name: drift.Value(name ?? 'User'),
      photoUrl: drift.Value(photoUrl),
      language: const drift.Value('en'),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
      isSynced: const drift.Value(false),
    );

    await _database.insertUser(user);
    AppLogger.info('User profile created/updated locally');
  }

  /// Sign out
  Future<Either<Failure, void>> signOut() async {
    try {
      // Sign out from Supabase
      await _supabaseClient.auth.signOut();
      await _googleSignIn.signOut();
      await _secureStorage.deleteAll();

      AppLogger.info('User signed out');
      return const Right(null);
    } catch (e) {
      AppLogger.error('Error signing out', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Get current user from local DB
  Future<Either<Failure, db.User?>> getCurrentUser() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        return const Right(null);
      }

      final user = await _database.getUserById(userId);
      return Right(user);
    } catch (e) {
      AppLogger.error('Error getting current user', e);
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  /// Update user profile
  Future<Either<Failure, void>> updateProfile({
    String? name,
    String? photoUrl,
    String? language,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        return const Left(UnauthorizedFailure());
      }

      // TODO: Update in Supabase
      // await _supabaseClient.from('users').update({
      //   if (name != null) 'name': name,
      //   if (photoUrl != null) 'photo_url': photoUrl,
      //   if (language != null) 'language': language,
      //   'updated_at': DateTime.now().toIso8601String(),
      // }).eq('id', userId);

      // Update in local DB
      final user = db.UsersCompanion(
        id: drift.Value(userId),
        name: name != null ? drift.Value(name) : const drift.Value.absent(),
        photoUrl: photoUrl != null
            ? drift.Value(photoUrl)
            : const drift.Value.absent(),
        language: language != null
            ? drift.Value(language)
            : const drift.Value.absent(),
        updatedAt: drift.Value(DateTime.now()),
        isSynced: const drift.Value(false),
      );

      await _database.updateUser(user);
      AppLogger.info('User profile updated locally');

      return const Right(null);
    } catch (e) {
      AppLogger.error('Error updating profile', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }
}
