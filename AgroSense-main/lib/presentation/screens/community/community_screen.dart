import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/demo_data_provider.dart';
import '../../../data/local/database/app_database.dart';
import '../../../providers/repository_providers.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  bool _isLoading = true;
  List<Post> _posts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if in developer mode
      if (AppConstants.isDeveloperMode) {
        // Load demo data - convert from Map to Post objects
        final demoPosts = DemoDataProvider.getDemoCommunityPosts(language: 'en');
        
        // Convert demo posts (Map) to Post objects
        final posts = demoPosts.map((postData) {
          return Post(
            id: postData['id'] as String,
            userId: postData['userId'] as String,
            userName: postData['userName'] as String,
            userPhotoUrl: postData['userAvatar'] as String?,
            title: postData['title'] as String,
            content: postData['content'] as String,
            imageUrls: postData['imageUrl'] as String?,
            upvotes: postData['likes'] as int,
            commentsCount: postData['comments'] as int,
            tags: null,
            createdAt: postData['createdAt'] as DateTime,
            updatedAt: postData['createdAt'] as DateTime,
            isSynced: false,
            isDeleted: false,
          );
        }).toList();
        
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      } else {
        // Load from database (real data)
        final database = ref.read(databaseProvider);
        final posts = await database.watchPosts(limit: 50).first;
        
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _upvotePost(Post post) async {
    try {
      final database = ref.read(databaseProvider);
      await database.incrementPostUpvotes(post.id);
      await _loadPosts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPostDetails(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailsScreen(post: post, onUpdate: _loadPosts),
      ),
    );
  }

  void _showCreatePostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostSheet(onPostCreated: _loadPosts),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Text('Error: $_error', style: AppTextStyles.bodyMedium),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadPosts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum, size: 64.sp, color: AppColors.textSecondary),
            SizedBox(height: 16.h),
            const Text('No posts yet', style: AppTextStyles.h3),
            SizedBox(height: 8.h),
            const Text('Be the first to share!', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return _buildPostCard(post);
        },
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    List<String> imageUrls = [];
    if (post.imageUrls != null) {
      try {
        imageUrls = List<String>.from(jsonDecode(post.imageUrls!));
      } catch (_) {}
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: () => _showPostDetails(post),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20.r,
                    backgroundColor: AppColors.primary,
                    backgroundImage: post.userPhotoUrl != null
                        ? NetworkImage(post.userPhotoUrl!)
                        : null,
                    child: post.userPhotoUrl == null
                        ? Text(
                            post.userName[0].toUpperCase(),
                            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                          )
                        : null,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName,
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _formatTimestamp(post.createdAt),
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                post.title,
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              Text(
                post.content.length > 150
                    ? '${post.content.substring(0, 150)}...'
                    : post.content,
                style: AppTextStyles.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (imageUrls.isNotEmpty) ...[
                SizedBox(height: 12.h),
                SizedBox(
                  height: 120.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length > 3 ? 3 : imageUrls.length,
                    itemBuilder: (context, i) => Container(
                      width: 120.w,
                      margin: EdgeInsets.only(right: 8.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        image: DecorationImage(
                          image: imageUrls[i].startsWith('http')
                              ? NetworkImage(imageUrls[i]) as ImageProvider
                              : FileImage(File(imageUrls[i])),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 12.h),
              Row(
                children: [
                  InkWell(
                    onTap: () => _upvotePost(post),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward, size: 20.sp, color: AppColors.primary),
                        SizedBox(width: 4.w),
                        Text('${post.upvotes}', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                  SizedBox(width: 24.w),
                  Row(
                    children: [
                      Icon(Icons.comment, size: 20.sp, color: AppColors.textSecondary),
                      SizedBox(width: 4.w),
                      Text('${post.commentsCount}', style: AppTextStyles.bodyMedium),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16.sp, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(timestamp);
    }
  }
}

class CreatePostSheet extends ConsumerStatefulWidget {
  final VoidCallback onPostCreated;

  const CreatePostSheet({super.key, required this.onPostCreated});

  @override
  ConsumerState<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<CreatePostSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<String> _imagePaths = [];
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _imagePaths.addAll(images.map((e) => e.path));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: ${e.toString()}')),
      );
    }
  }

  Future<void> _createPost() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter content')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final database = ref.read(databaseProvider);
      final authRepo = ref.read(authRepositoryProvider);
      
      final userId = await authRepo.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final user = await database.getUserById(userId);
      final now = DateTime.now();

      final companion = PostsCompanion(
        id: Value(const Uuid().v4()),
        userId: Value(userId),
        userName: Value(user?.name ?? 'Anonymous'),
        userPhotoUrl: Value(user?.photoUrl),
        title: Value(_titleController.text.trim()),
        content: Value(_contentController.text.trim()),
        imageUrls: Value(_imagePaths.isEmpty ? null : jsonEncode(_imagePaths)),
        upvotes: const Value(0),
        commentsCount: const Value(0),
        createdAt: Value(now),
        updatedAt: Value(now),
        isSynced: const Value(false),
        isDeleted: const Value(false),
      );

      await database.insertPost(companion);

      if (!mounted) return;
      Navigator.pop(context);
      widget.onPostCreated();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 16.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('Create Post', style: AppTextStyles.h3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'What\'s on your mind?',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 16.h),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.image),
              label: const Text('Add Images'),
            ),
            if (_imagePaths.isNotEmpty) ...[
              SizedBox(height: 12.h),
              SizedBox(
                height: 100.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagePaths.length,
                  itemBuilder: (context, index) => Stack(
                    children: [
                      Container(
                        width: 100.w,
                        margin: EdgeInsets.only(right: 8.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          image: DecorationImage(
                            image: FileImage(File(_imagePaths[index])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => setState(() => _imagePaths.removeAt(index)),
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, size: 16.sp, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _createPost,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

class PostDetailsScreen extends ConsumerStatefulWidget {
  final Post post;
  final VoidCallback onUpdate;

  const PostDetailsScreen({
    super.key,
    required this.post,
    required this.onUpdate,
  });

  @override
  ConsumerState<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends ConsumerState<PostDetailsScreen> {
  List<Comment> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);

    try {
      final database = ref.read(databaseProvider);
      final comments = await database.getCommentsByPostId(widget.post.id);
      
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _upvotePost() async {
    try {
      final database = ref.read(databaseProvider);
      await database.incrementPostUpvotes(widget.post.id);
      widget.onUpdate();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddCommentDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCommentDialog(
        postId: widget.post.id,
        onCommentAdded: () {
          _loadComments();
          widget.onUpdate();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> imageUrls = [];
    if (widget.post.imageUrls != null) {
      try {
        imageUrls = List<String>.from(jsonDecode(widget.post.imageUrls!));
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24.r,
                        backgroundColor: AppColors.primary,
                        backgroundImage: widget.post.userPhotoUrl != null
                            ? NetworkImage(widget.post.userPhotoUrl!)
                            : null,
                        child: widget.post.userPhotoUrl == null
                            ? Text(
                                widget.post.userName[0].toUpperCase(),
                                style: AppTextStyles.h4.copyWith(color: Colors.white),
                              )
                            : null,
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.post.userName, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            DateFormat('MMM dd, yyyy • HH:mm').format(widget.post.createdAt),
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text(widget.post.title, style: AppTextStyles.h3),
                  SizedBox(height: 12.h),
                  Text(widget.post.content, style: AppTextStyles.bodyMedium),
                  if (imageUrls.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    ...imageUrls.map((url) => Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      height: 200.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        image: DecorationImage(
                          image: url.startsWith('http')
                              ? NetworkImage(url) as ImageProvider
                              : FileImage(File(url)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),),
                  ],
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _upvotePost,
                        icon: const Icon(Icons.arrow_upward),
                        label: Text('${widget.post.upvotes}'),
                      ),
                      SizedBox(width: 12.w),
                      OutlinedButton.icon(
                        onPressed: _showAddCommentDialog,
                        icon: const Icon(Icons.comment),
                        label: const Text('Comment'),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Text('Comments (${_comments.length})', style: AppTextStyles.h4),
                  SizedBox(height: 12.h),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_comments.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.h),
                        child: const Text('No comments yet', style: AppTextStyles.bodyMedium),
                      ),
                    )
                  else
                    ..._comments.map((comment) => Card(
                      margin: EdgeInsets.only(bottom: 8.h),
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16.r,
                                  backgroundColor: AppColors.secondary,
                                  child: Text(
                                    comment.userName[0].toUpperCase(),
                                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment.userName,
                                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        DateFormat('MMM dd, HH:mm').format(comment.createdAt),
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Text(comment.content, style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ),
                    ),),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddCommentDialog extends ConsumerStatefulWidget {
  final String postId;
  final VoidCallback onCommentAdded;

  const AddCommentDialog({
    super.key,
    required this.postId,
    required this.onCommentAdded,
  });

  @override
  ConsumerState<AddCommentDialog> createState() => _AddCommentDialogState();
}

class _AddCommentDialogState extends ConsumerState<AddCommentDialog> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final database = ref.read(databaseProvider);
      final authRepo = ref.read(authRepositoryProvider);
      
      final userId = await authRepo.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final user = await database.getUserById(userId);
      final now = DateTime.now();

      final companion = CommentsCompanion(
        id: Value(const Uuid().v4()),
        postId: Value(widget.postId),
        userId: Value(userId),
        userName: Value(user?.name ?? 'Anonymous'),
        userPhotoUrl: Value(user?.photoUrl),
        content: Value(_commentController.text.trim()),
        createdAt: Value(now),
        updatedAt: Value(now),
        isSynced: const Value(false),
        isDeleted: const Value(false),
      );

      await database.insertComment(companion);
      await database.incrementPostCommentsCount(widget.postId);

      if (!mounted) return;
      Navigator.pop(context);
      widget.onCommentAdded();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Comment'),
      content: TextField(
        controller: _commentController,
        decoration: const InputDecoration(
          hintText: 'Write your comment...',
        ),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _addComment,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Post'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
