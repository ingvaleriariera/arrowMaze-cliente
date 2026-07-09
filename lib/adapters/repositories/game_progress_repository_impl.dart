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

      // Delegate to the mapper (single source of truth for the wire
      // format, also used to parse the response below) rather than
      // rebuilding the payload by hand here. When there's no local
      // progress yet, deliberately send no `coins` at all — GameProgress's
      // default (9999, a temporary dev-testing value — see game_progress
      // .dart) must never be sent as if it were a real balance, and
      // omitting the key entirely tells the backend to leave whatever
      // balance it already has untouched.
      final requestBody = localProgress != null
          ? progressMapper.toMap(localProgress)
          : {'levels': <Map<String, dynamic>>[]};

      debugPrint('📤 Syncing to backend via POST /api/v1/progress/sync');
      debugPrint('   Request body: $requestBody');

      // Call backend sync endpoint
      final responseJson = await apiClient.post('/api/v1/progress/sync', requestBody);
      
      debugPrint('📥 Backend response received: $responseJson');
      
      // Parse response as progress (backend returns updated progress).
      // Pass userId to mapper since it's not in the response. The backend
      // now actually persists coins (see PlayerProgress.setCoins on the
      // server) and always returns the real balance, so we trust it
      // directly instead of overriding it with the local value.
      final syncedProgress = progressMapper.fromMap(responseJson, userId: userId);

      // avatarEmoji never goes through the backend at all (see GameProgress
      // — local-only by design), so fromMap() always hands back the
      // default. Carry over whatever was already chosen locally, or every
      // sync() call would silently reset the player's avatar.
      if (localProgress != null) {
        syncedProgress.avatarEmoji = localProgress.avatarEmoji;
      }

      // TEMPORARY, client-only: force a generous testing balance on every
      // sync instead of trusting the backend's real (mostly zero) balance.
      // There's no real coin-earning economy yet (RF09 — see GameProgress's
      // own default), so respecting the real persisted balance here just
      // makes power-ups untestable. Spending still works normally locally
      // between syncs; this only resets the floor back up on login.
      // Remove once players can actually earn coins through gameplay.
      syncedProgress.coins = 9999;

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
