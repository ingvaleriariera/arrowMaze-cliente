import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/adapters/api/api_client.dart';
import 'package:arrow_maze_cliente_copy/adapters/mappers/progress_mapper.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/game_progress_database.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_progress.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_game_progress_repository.dart';

class GameProgressRepositoryImpl implements IGameProgressRepository {
  final ApiClient apiClient;
  final ProgressMapper progressMapper;
  final GameProgressDatabase database;

  // In-memory cache (optimization layer on top of sqflite)
  final Map<String, GameProgress> _localCache = {};

  GameProgressRepositoryImpl({
    required this.apiClient,
    required this.progressMapper,
    required this.database,
  });

  @override
  Future<void> save(GameProgress progress) async {
    debugPrint('💾 GameProgressRepositoryImpl.save: Saving progress for ${progress.userId}');

    try {
      // Save to sqflite (persistent storage)
      await database.saveProgress(
        progress.userId,
        progress.completedLevels,
        progress.bestScores,
        progress.coins,
        progress.avatarEmoji,
      );

      // Also keep in-memory cache in sync for optimization
      _localCache[progress.userId] = progress;
      debugPrint('✅ Saved to sqflite and local cache');
    } catch (e) {
      debugPrint('❌ GameProgressRepositoryImpl.save: Error - $e');
      // Even if sqflite fails, keep it in memory cache as fallback
      _localCache[progress.userId] = progress;
      rethrow;
    }
  }

  @override
  Future<GameProgress?> get(String userId) async {
    debugPrint('📖 GameProgressRepositoryImpl.get: Reading progress for $userId');

    // Step 1: Try in-memory cache first (fastest)
    var progress = _localCache[userId];
    if (progress != null) {
      debugPrint('⚡ Found in memory cache: ${progress.completedLevels.length} completed levels, ${progress.coins} coins');
      return progress;
    }

    // Step 2: Try sqflite (persistent local storage)
    try {
      final dbRecord = await database.getProgress(userId);
      if (dbRecord != null) {
        debugPrint('📖 Found in sqflite: Loading progress');
        progress = _reconstructProgressFromDatabase(dbRecord, userId);
        _localCache[userId] = progress;  // Populate in-memory cache
        debugPrint('✅ Loaded from sqflite: ${progress.completedLevels.length} completed levels, ${progress.coins} coins');
        return progress;
      }
    } catch (e) {
      debugPrint('⚠️  GameProgressRepositoryImpl.get: Error reading from sqflite - $e');
      // Continue to backend fallback
    }

    // Step 3: Fallback to backend (for new users or first sync)
    debugPrint('ℹ️  No local progress found - returning null (new user or first sync)');
    return null;
  }

  GameProgress _reconstructProgressFromDatabase(
    Map<String, dynamic> dbRecord,
    String userId,
  ) {
    final completedLevels = List<String>.from(
      jsonDecode(dbRecord['completedLevels'] as String) as List<dynamic>,
    );
    final bestScores = Map<String, int>.from(
      jsonDecode(dbRecord['bestScores'] as String) as Map<String, dynamic>,
    );

    return GameProgress(
      userId: userId,
      completedLevels: completedLevels,
      bestScores: bestScores,
      coins: dbRecord['coins'] as int,
      avatarEmoji: dbRecord['avatarEmoji'] as String,
    );
  }

  @override
  Future<GameProgress> sync(String userId) async {
    debugPrint('🔄 GameProgressRepositoryImpl.sync: Starting sync for $userId');

    try {
      // Get current local progress (from cache, sqflite, or null)
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

      // Use the greater balance between local and backend (protection against
      // data loss). Backend is the source of truth, but if local somehow has
      // more (race condition or sync issue), preserve the higher value.
      if (localProgress != null && localProgress.coins > syncedProgress.coins) {
        syncedProgress.coins = localProgress.coins;
      }

      // Save synced progress locally (to both sqflite and cache)
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
