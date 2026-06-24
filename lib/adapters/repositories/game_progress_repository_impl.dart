import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/adapters/api/api_client.dart';
import 'package:arrow_maze_cliente_copy/adapters/mappers/progress_mapper.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_progress.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_game_progress_repository.dart';

class GameProgressRepositoryImpl implements IGameProgressRepository {
  final ApiClient apiClient;
  final ProgressMapper progressMapper;

  // In-memory cache simulating sqflite local storage
  final Map<String, GameProgress> _localCache = {};

  GameProgressRepositoryImpl({
    required this.apiClient,
    required this.progressMapper,
  });

  @override
  Future<void> save(GameProgress progress) async {
    debugPrint('💾 GameProgressRepositoryImpl.save: Saving progress for ${progress.userId}');
    _localCache[progress.userId] = progress;
    debugPrint('✅ Saved to local cache');
  }

  @override
  Future<GameProgress?> get(String userId) async {
    debugPrint('📖 GameProgressRepositoryImpl.get: Reading progress from local cache for $userId');
    
    final progress = _localCache[userId];
    if (progress != null) {
      debugPrint('✅ Found in cache: ${progress.completedLevels.length} completed levels, ${progress.coins} coins');
      return progress;
    }
    
    debugPrint('ℹ️  No local progress found - returning null (new user)');
    return null;
  }

  @override
  Future<GameProgress> sync(String userId) async {
    debugPrint('🔄 GameProgressRepositoryImpl.sync: Starting sync for $userId');
    
    try {
      // Get current local progress
      final localProgress = await get(userId);
      debugPrint('📝 Local progress: ${localProgress?.completedLevels.length ?? 0} completed levels, coins: ${localProgress?.coins ?? 0}');

      // Build request body in the exact format backend expects
      final List<Map<String, dynamic>> levelsList = [];
      
      if (localProgress != null) {
        // Map each bestScore entry to the expected format
        for (final entry in localProgress.bestScores.entries) {
          levelsList.add({
            'levelId': entry.key,
            'bestScore': entry.value,
            'completedAt': DateTime.now().toIso8601String(),
          });
        }
        debugPrint('📝 Mapped ${levelsList.length} levels to sync format');
      } else {
        debugPrint('📝 No local progress - sending empty levels array');
      }

      // Always include "levels" key, even if empty
      final requestBody = {
        'levels': levelsList,
      };
      
      debugPrint('📤 Syncing to backend via POST /api/v1/progress/sync');
      debugPrint('   Request body: $requestBody');

      // Call backend sync endpoint
      final responseJson = await apiClient.post('/api/v1/progress/sync', requestBody);
      
      debugPrint('📥 Backend response received: $responseJson');
      
      // Parse response as progress (backend returns updated progress)
      // Pass userId to mapper since it's not in the response
      final syncedProgress = progressMapper.fromMap(responseJson, userId: userId);
      
      // Save synced progress locally
      await save(syncedProgress);
      
      debugPrint('✅ sync: Synced and saved');
      debugPrint('   Completed: ${syncedProgress.completedLevels.length}, Coins: ${syncedProgress.coins}');
      
      return syncedProgress;
    } catch (e, stackTrace) {
      debugPrint('❌ sync: Error during sync - $e');
      debugPrint('   StackTrace: $stackTrace');
      
      // If sync fails, return local progress or empty
      final fallback = await get(userId) ?? GameProgress(userId: userId);
      debugPrint('   Returning fallback: ${fallback.completedLevels.length} completed levels');
      return fallback;
    }
  }
}
