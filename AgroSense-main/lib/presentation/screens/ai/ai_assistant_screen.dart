import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/demo_data_provider.dart';
import '../../../core/utils/logger.dart';
import '../../../data/local/database/app_database.dart';
import '../../../providers/repository_providers.dart';

/// AI Assistant Screen with Gemini AI Chat
class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    try {
      final database = ref.read(databaseProvider);
      final userId = await ref.read(currentUserIdProvider.future);
      
      if (userId == null) {
        setState(() => _isInitializing = false);
        return;
      }

      final messages = await database.getChatMessagesByUserId(userId);
      setState(() {
        _messages = messages;
        _isInitializing = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    // Get userId first
    final userId = await ref.read(currentUserIdProvider.future) ?? 'demo_user';

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        message: userMessage,
        response: '',
        isUser: true,
        timestamp: DateTime.now(),
      ),);
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // Check if in developer mode and asking about planting/crops
      if (AppConstants.isDeveloperMode && 
          (userMessage.toLowerCase().contains('plant') || 
           userMessage.toLowerCase().contains('crop') ||
           userMessage.toLowerCase().contains('sow') ||
           userMessage.toLowerCase().contains('grow'))) {
        
        // Use demo response
        await Future.delayed(const Duration(milliseconds: 800)); // Simulate AI thinking
        final demoResponse = DemoDataProvider.getDemoAIPlantingAdvice(language: 'en');
        
        final aiMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          message: userMessage,
          response: demoResponse,
          isUser: false,
          timestamp: DateTime.now(),
        );

        setState(() {
          _messages.add(aiMessage);
          _isLoading = false;
        });
        _scrollToBottom();
        return;
      }

      // Otherwise use real AI
      final aiRepo = ref.read(aiRepositoryProvider);
      final userContext = await _buildContext();
      
      final result = await aiRepo.sendMessage(
        userId: userId,
        message: userMessage,
        context: userContext,
      );

      result.fold(
        (failure) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${failure.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        (response) {
          final aiMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: userId,
            message: userMessage,
            response: response,
            isUser: false,
            timestamp: DateTime.now(),
          );

          setState(() {
            _messages.add(aiMessage);
            _isLoading = false;
          });
          _scrollToBottom();
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _buildContext() async {
    final database = ref.read(databaseProvider);
    final userId = await ref.read(currentUserIdProvider.future);
    
    if (userId == null || userId.isEmpty) return {};

    try {
      final fields = await database.getFieldsByUserId(userId);
      final tasks = await database.watchTasksByUserId(userId).first;

      return {
        'fieldsCount': fields.length,
        'pendingTasks': tasks.where((t) => !t.isCompleted && !t.isDeleted).length,
        'crops': fields.map((f) => f.cropType).where((c) => c != null).toSet().toList(),
      };
    } catch (e) {
      AppLogger.error('Error building context', e);
      return {};
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('Are you sure you want to delete all chat messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _messages.clear());
      // Note: Implement database clear method if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.smart_toy, size: 24),
            const SizedBox(width: 8),
            Text(
              'AgroSense AI',
              style: AppTextStyles.h2.copyWith(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _messages.isEmpty ? null : _clearChat,
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // AI Info Banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            color: AppColors.primary.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16.sp, color: AppColors.primary),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Powered by Gemini AI • Get farming advice, crop tips, and pest management help',
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: _isInitializing
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16.w),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _buildMessageBubble(msg);
                        },
                      ),
          ),

          // Loading Indicator
          if (_isLoading)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  const CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(width: 12.w),
                  const Text('AI is thinking...', style: AppTextStyles.bodySmall),
                ],
              ),
            ),

          // Input Field
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything about farming...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.mic, color: AppColors.primary),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Voice input coming soon!')),
                          );
                        },
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8.w),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  mini: true,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smart_toy, size: 80.sp, color: AppColors.primary.withOpacity(0.3)),
            SizedBox(height: 16.h),
            const Text(
              'Welcome to AgroSense AI!',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Start a conversation by asking any farming-related question',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('What crop should I plant?'),
                _buildSuggestionChip('How to control pests?'),
                _buildSuggestionChip('Best fertilizer for wheat?'),
                _buildSuggestionChip('When to harvest rice?'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text, style: AppTextStyles.bodySmall),
      onPressed: () {
        _messageController.text = text;
        _sendMessage();
      },
      backgroundColor: AppColors.surface,
      side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    final displayText = isUser ? msg.message : msg.response;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: isUser ? Radius.circular(16.r) : Radius.zero,
            bottomRight: isUser ? Radius.zero : Radius.circular(16.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Row(
                children: [
                  Icon(Icons.smart_toy, size: 16.sp, color: AppColors.primary),
                  SizedBox(width: 4.w),
                  Text(
                    'AI Assistant',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            if (!isUser) SizedBox(height: 4.h),
            Text(
              displayText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isUser ? Colors.white : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              _formatTime(msg.timestamp),
              style: AppTextStyles.caption.copyWith(
                color: isUser ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
