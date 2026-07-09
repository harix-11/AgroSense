import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/error/failures.dart';
import '../../core/error/exceptions.dart';
import '../../core/constants/app_constants.dart';
import '../local/database/app_database.dart' as db;
import '../../core/utils/logger.dart';

/// Repository for AI Assistant operations
/// Uses Google Gemini API for farming advice
class AIRepository {
  final db.AppDatabase _database;
  late final GenerativeModel _model;

  AIRepository({
    required db.AppDatabase database,
    String? apiKey,
  }) : _database = database {
    final key = apiKey ?? AppConstants.geminiApiKey;
    
    if (key == 'YOUR_GEMINI_API_KEY' || key.isEmpty) {
      AppLogger.warning('Gemini API key not configured - AI features will not work');
    }

    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: key,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
  }

  /// Get chat history for user
  Future<Either<Failure, List<db.ChatMessage>>> getChatHistory(String userId) async {
    try {
      final messages = await _database.getChatMessagesByUserId(userId);
      return Right(messages);
    } on DatabaseException catch (e) {
      AppLogger.error('Error getting chat history', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error getting chat history', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Send message to AI and get response
  Future<Either<Failure, String>> sendMessage({
    required String userId,
    required String message,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Build context-aware prompt
      final prompt = _buildPrompt(message, context);

      // Get AI response
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        return const Left(AIFailure(message: 'No response from AI'));
      }

      final aiResponse = response.text!;

      // Save to chat history
      await _saveChatMessage(userId, message, aiResponse);

      AppLogger.info('AI response generated successfully');
      return Right(aiResponse);
    } on GenerativeAIException catch (e) {
      AppLogger.error('AI generation error', e);
      return Left(AIFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error in AI chat', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Get farming advice based on weather
  Future<Either<Failure, String>> getWeatherBasedAdvice({
    required Map<String, dynamic> weatherData,
    String? cropType,
  }) async {
    try {
      final prompt = '''
You are an expert agricultural advisor. Based on the following weather conditions, 
provide farming advice in 3-4 bullet points.

Weather Data:
- Temperature: ${weatherData['temperature']}°C
- Humidity: ${weatherData['humidity']}%
- Wind Speed: ${weatherData['windSpeed']} km/h
- Precipitation: ${weatherData['precipitation']} mm
${cropType != null ? '- Crop: $cropType' : ''}

Provide practical, actionable advice for farmers. Keep it concise and clear.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        return const Left(AIFailure(message: 'No advice generated'));
      }

      AppLogger.info('Weather advice generated');
      return Right(response.text!);
    } on GenerativeAIException catch (e) {
      AppLogger.error('AI generation error for weather advice', e);
      return Left(AIFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error generating weather advice', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Analyze crop disease from description
  Future<Either<Failure, String>> analyzeCropIssue({
    required String description,
    String? cropType,
  }) async {
    try {
      final prompt = '''
You are an agricultural expert specializing in crop diseases and pest management.
Analyze the following crop issue and provide:
1. Possible diagnosis
2. Recommended treatment
3. Prevention measures

${cropType != null ? 'Crop Type: $cropType\n' : ''}
Issue Description: $description

Provide clear, practical advice for farmers. Keep the response concise.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        return const Left(AIFailure(message: 'No analysis generated'));
      }

      AppLogger.info('Crop issue analysis generated');
      return Right(response.text!);
    } on GenerativeAIException catch (e) {
      AppLogger.error('AI generation error for crop analysis', e);
      return Left(AIFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error analyzing crop issue', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Get task recommendations based on season and crop
  Future<Either<Failure, List<String>>> getTaskRecommendations({
    required String cropType,
    required DateTime currentDate,
    String? fieldConditions,
  }) async {
    try {
      final month = currentDate.month;
      final season = _getSeason(month);

      final prompt = '''
As an agricultural expert, recommend 5-7 essential farming tasks for:
- Crop: $cropType
- Season: $season (Month: $month)
${fieldConditions != null ? '- Field Conditions: $fieldConditions' : ''}

List only the task names, one per line, without numbering or explanations.
Example format:
Irrigation
Fertilizer application
Pest monitoring
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        return const Left(AIFailure(message: 'No recommendations generated'));
      }

      final tasks = response.text!
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.trim())
          .toList();

      AppLogger.info('Task recommendations generated: ${tasks.length}');
      return Right(tasks);
    } on GenerativeAIException catch (e) {
      AppLogger.error('AI generation error for task recommendations', e);
      return Left(AIFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error generating recommendations', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Clear chat history
  Future<Either<Failure, bool>> clearChatHistory(String userId) async {
    try {
      await _database.deleteChatMessagesByUserId(userId);
      AppLogger.info('Chat history cleared for user: $userId');
      return const Right(true);
    } on DatabaseException catch (e) {
      AppLogger.error('Error clearing chat history', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error clearing chat history', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Build context-aware prompt
  String _buildPrompt(String message, Map<String, dynamic>? context) {
    final buffer = StringBuffer();
    
    buffer.writeln('You are an expert agricultural advisor helping farmers.');
    buffer.writeln('Provide practical, actionable advice in simple language.');
    buffer.writeln();

    if (context != null) {
      if (context['cropType'] != null) {
        buffer.writeln('Context: The farmer grows ${context['cropType']}.');
      }
      if (context['location'] != null) {
        buffer.writeln('Location: ${context['location']}');
      }
      if (context['fieldArea'] != null) {
        buffer.writeln('Field Area: ${context['fieldArea']} hectares');
      }
      buffer.writeln();
    }

    buffer.writeln('Farmer\'s Question: $message');
    
    return buffer.toString();
  }

  /// Save chat message to database
  Future<void> _saveChatMessage(String userId, String message, String response) async {
    try {
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();

      // Save user message
      await _database.insertChatMessage(
        db.ChatMessagesCompanion(
          id: drift.Value('${messageId}_user'),
          userId: drift.Value(userId),
          message: drift.Value(message),
          response: const drift.Value(''),
          isUser: const drift.Value(true),
          timestamp: drift.Value(now),
        ),
      );

      // Save AI response
      await _database.insertChatMessage(
        db.ChatMessagesCompanion(
          id: drift.Value('${messageId}_ai'),
          userId: drift.Value(userId),
          message: const drift.Value(''),
          response: drift.Value(response),
          isUser: const drift.Value(false),
          timestamp: drift.Value(now),
        ),
      );

      AppLogger.info('Chat messages saved');
    } catch (e) {
      AppLogger.error('Error saving chat messages', e);
    }
  }

  /// Get season from month
  String _getSeason(int month) {
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer/Monsoon';
    if (month >= 9 && month <= 11) return 'Autumn';
    return 'Winter';
  }
}
