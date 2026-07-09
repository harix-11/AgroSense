import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:io';
import 'dart:convert';
import '../../core/error/failures.dart';
import '../../core/error/exceptions.dart';
import '../local/database/app_database.dart' as db;
import '../../core/utils/logger.dart';

/// Repository for Community operations
/// Manages posts, comments, and social interactions
class CommunityRepository {
  final db.AppDatabase _database;

  CommunityRepository({
    required db.AppDatabase database,
  }) : _database = database;

  /// Watch all posts (real-time feed)
  Stream<Either<Failure, List<db.Post>>> watchPosts({int limit = 20}) {
    try {
      return _database.watchAllPosts(limit).map((posts) => Right(posts));
    } catch (e) {
      AppLogger.error('Error watching posts', e);
      return Stream.value(Left(DatabaseFailure(message: e.toString())));
    }
  }

  /// Get posts by user ID
  Future<Either<Failure, List<db.Post>>> getPostsByUserId(String userId) async {
    try {
      final posts = await _database.getPostsByUserId(userId);
      return Right(posts);
    } on DatabaseException catch (e) {
      AppLogger.error('Error getting posts by user', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error getting posts', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Create new post with images
  Future<Either<Failure, String>> createPost({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String title,
    required String content,
    List<File>? images,
    List<String>? tags,
  }) async {
    try {
      final postId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();

      // TODO: Upload images to Supabase Storage
      List<String> imageUrls = [];
      if (images != null && images.isNotEmpty) {
        AppLogger.info(
            'Image upload to Supabase not yet implemented. Images will be stored locally.');
        // For now, store local file paths
        imageUrls = images.map((file) => file.path).toList();
      }

      final post = db.PostsCompanion(
        id: drift.Value(postId),
        userId: drift.Value(userId),
        userName: drift.Value(userName),
        userPhotoUrl: drift.Value(userPhotoUrl),
        title: drift.Value(title),
        content: drift.Value(content),
        imageUrls:
            drift.Value(imageUrls.isNotEmpty ? jsonEncode(imageUrls) : null),
        tags: drift.Value(tags != null ? jsonEncode(tags) : null),
        upvotes: const drift.Value(0),
        commentsCount: const drift.Value(0),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
        isDeleted: const drift.Value(false),
      );

      await _database.insertPost(post);
      AppLogger.info('Post created: $postId');

      // TODO: Sync to Supabase in background

      return Right(postId);
    } on DatabaseException catch (e) {
      AppLogger.error('Error creating post', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error creating post', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Update post
  Future<Either<Failure, bool>> updatePost({
    required String postId,
    String? title,
    String? content,
    List<String>? tags,
  }) async {
    try {
      final now = DateTime.now();

      final postUpdate = db.PostsCompanion(
        id: drift.Value(postId),
        title: title != null ? drift.Value(title) : const drift.Value.absent(),
        content:
            content != null ? drift.Value(content) : const drift.Value.absent(),
        tags: tags != null
            ? drift.Value(jsonEncode(tags))
            : const drift.Value.absent(),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
      );

      final result = await _database.updatePost(postUpdate);
      AppLogger.info('Post updated: $postId');

      // TODO: Sync to Supabase in background

      return Right(result);
    } on DatabaseException catch (e) {
      AppLogger.error('Error updating post', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error updating post', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Delete post (soft delete)
  Future<Either<Failure, bool>> deletePost(String postId) async {
    try {
      final result = await _database.deletePost(postId);
      AppLogger.info('Post deleted: $postId');

      // TODO: Sync to Supabase in background

      return Right(result > 0);
    } on DatabaseException catch (e) {
      AppLogger.error('Error deleting post', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error deleting post', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Upvote post
  Future<Either<Failure, bool>> upvotePost(String postId) async {
    try {
      final result = await _database.incrementPostUpvotes(postId);
      AppLogger.info('Post upvoted: $postId');

      // TODO: Sync to Supabase in background

      return Right(result > 0);
    } on DatabaseException catch (e) {
      AppLogger.error('Error upvoting post', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error upvoting post', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Get comments for a post
  Future<Either<Failure, List<db.Comment>>> getCommentsByPostId(
      String postId) async {
    try {
      final comments = await _database.getCommentsByPostId(postId);
      return Right(comments);
    } on DatabaseException catch (e) {
      AppLogger.error('Error getting comments', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error getting comments', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Add comment to post
  Future<Either<Failure, String>> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String content,
  }) async {
    try {
      final commentId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();

      final comment = db.CommentsCompanion(
        id: drift.Value(commentId),
        postId: drift.Value(postId),
        userId: drift.Value(userId),
        userName: drift.Value(userName),
        userPhotoUrl: drift.Value(userPhotoUrl),
        content: drift.Value(content),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
        isDeleted: const drift.Value(false),
      );

      await _database.insertComment(comment);

      // Increment comment count on post
      await _database.incrementPostCommentsCount(postId);

      AppLogger.info('Comment added: $commentId');

      // TODO: Sync to Supabase in background

      return Right(commentId);
    } on DatabaseException catch (e) {
      AppLogger.error('Error adding comment', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error adding comment', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Delete comment (soft delete)
  Future<Either<Failure, bool>> deleteComment(
      String commentId, String postId) async {
    try {
      final result = await _database.deleteComment(commentId);

      // Decrement comment count on post
      await _database.decrementPostCommentsCount(postId);

      AppLogger.info('Comment deleted: $commentId');

      // TODO: Sync to Supabase in background

      return Right(result > 0);
    } on DatabaseException catch (e) {
      AppLogger.error('Error deleting comment', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error deleting comment', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }
}
